import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/sumup_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/app_action_sheet.dart';

class WardrobeActionSheet extends StatefulWidget {
  final List<WardrobeSlot> initialSlots;
  final SyncService syncService;
  final Function(int? id, String secret, {String? groupId}) onSyncMonitor;
  final String Function() onGenerateSecret;
  final VoidCallback? onCompleted;

  const WardrobeActionSheet({
    super.key,
    required this.initialSlots,
    required this.syncService,
    required this.onSyncMonitor,
    required this.onGenerateSecret,
    this.onCompleted,
  });

  @override
  State<WardrobeActionSheet> createState() => _WardrobeActionSheetState();
}

class _WardrobeActionSheetState extends State<WardrobeActionSheet> {
  bool _isProcessingSumUp = false;
  String _sumUpStatusText = 'Warte auf Terminal...';
  double _basePrice = 0.0;
  bool _isLoadingPrice = true;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    try {
      final price = await widget.syncService.getGlobalTicketPrice();
      if (mounted) {
        setState(() {
          _basePrice = price;
          _isLoadingPrice = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPrice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WardrobeSlot>>(
      stream: widget.syncService.watchSlots(),
      builder: (context, snapshot) {
        final allSlots = snapshot.data ?? [];
        
        // Match our initial slots to their current status in DB
        final currentSlots = widget.initialSlots.map((initial) {
          return allSlots.firstWhere((s) => s.id == initial.id, orElse: () => initial);
        }).toList();

        if (currentSlots.isEmpty) return const SizedBox.shrink();

        // If multiple slots, we are in group mode. If one, check its status.
        final bool isGroup = currentSlots.length > 1;
        final firstSlot = currentSlots.first;
        final bool isNewCheckIn = isGroup || firstSlot.status == 'free' || firstSlot.status == 'marked';
        
        String title = isGroup ? '${currentSlots.length} Jacken' : 'Bügel ${firstSlot.id}';
        String subtitle = _getStatusLabel(firstSlot.status);
        
        if (isNewCheckIn) {
          final total = _basePrice * currentSlots.length;
          subtitle = 'Zahlung ausstehend: ${total.toStringAsFixed(2)} €';
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: AppActionSheet(
            key: ValueKey('${currentSlots.length}_${firstSlot.status}'),
            title: title,
            subtitle: subtitle,
            actions: _buildActions(currentSlots, isNewCheckIn),
          ),
        );
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'free': return 'Verfügbar';
      case 'unpaid': return 'Warte auf Zahlung';
      case 'active': return 'Belegt';
      case 'temporary': return 'Temporär draußen';
      case 'marked': return 'Warte auf Zahlung';
      default: return '';
    }
  }

  List<SheetAction> _buildActions(List<WardrobeSlot> slots, bool isNewCheckIn) {
    final actions = <SheetAction>[];
    final firstSlot = slots.first;
    final bool canPay = isNewCheckIn || firstSlot.status == 'unpaid';

    if (canPay) {
      actions.add(SheetAction(
        leading: _isProcessingSumUp 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.active))
            : const Icon(Icons.contactless_outlined, color: AppTheme.active),
        label: _isProcessingSumUp ? _sumUpStatusText : 'Kontaktloses bezahlen',
        color: AppTheme.active,
        onTap: _isProcessingSumUp ? null : () => _handlePayment(slots, 'nfc'),
      ));

      actions.add(SheetAction(
        icon: Icons.euro,
        label: 'Bar bezahlen',
        color: AppTheme.secret,
        onTap: _isProcessingSumUp ? null : () => _handlePayment(slots, 'bar'),
      ));
    } else {
      // Existing slot actions (Active, Temporary, etc.)
      if (firstSlot.status == 'active' || firstSlot.status == 'temporary') {
        if (firstSlot.status == 'active') {
          actions.add(SheetAction(
            icon: Icons.pause,
            label: 'Temporärer Ausgang',
            color: AppTheme.temporary,
            onTap: () async {
              final updated = firstSlot.copyWith(status: 'temporary', updatedAt: DateTime.now());
              await _updateAndPop(updated);
            },
          ));
        } else {
          actions.add(SheetAction(
            icon: Icons.play_arrow,
            label: 'Wieder zurück',
            color: AppTheme.active,
            onTap: () async {
              final updated = firstSlot.copyWith(status: 'active', updatedAt: DateTime.now());
              await _updateAndPop(updated);
            },
          ));
        }

        actions.add(SheetAction(
          icon: Icons.logout,
          label: 'Endgültig auschecken',
          color: AppTheme.free,
          onTap: () async {
            final updated = firstSlot.copyWith(
              status: 'free',
              isPaid: false,
              secret: '',
              paymentMethod: 'none',
              groupId: '',
              updatedAt: DateTime.now(),
            );
            await _updateAndPop(updated);
          },
        ));
      }
    }

    return actions;
  }

  Future<void> _handlePayment(List<WardrobeSlot> slots, String method) async {
    final String? groupId = slots.length > 1 ? Uuid().v4() : null;
    final secret = widget.onGenerateSecret();
    
    if (method == 'nfc') {
      setState(() {
        _isProcessingSumUp = true;
        _sumUpStatusText = 'Warte auf Terminal...';
      });

      try {
        final checkoutId = await SumUpService().triggerTerminalPayment(
          slotCount: slots.length,
          slotIds: slots.map((s) => s.id).toList(),
        );

        if (checkoutId != null) {
          bool isPaid = false;
          int attempts = 0;
          const maxAttempts = 90;

          while (!isPaid && attempts < maxAttempts && mounted) {
            setState(() => _sumUpStatusText = 'Warte auf Zahlung...');
            final payStatus = await SumUpService().checkPaymentStatus(checkoutId);

            if (payStatus == 'PAID') {
              isPaid = true;
              await _finalizeGroup(slots, groupId, secret, 'nfc');
            } else if (payStatus == 'FAILED' || payStatus == 'CANCELLED') {
              throw 'Zahlung wurde abgebrochen oder ist fehlgeschlagen.';
            }

            if (!isPaid) {
              await Future.delayed(const Duration(seconds: 2));
              attempts++;
            }
          }
          if (!isPaid && mounted) throw 'Zeitüberschreitung beim Bezahlen.';
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler: $e', isError: true));
        setState(() => _isProcessingSumUp = false);
      }
    } else {
      await _finalizeGroup(slots, groupId, secret, 'bar');
    }
  }

  Future<void> _finalizeGroup(List<WardrobeSlot> slots, String? groupId, String secret, String method) async {
    final updatedSlots = slots.map((s) => s.copyWith(
      status: 'active',
      isPaid: true,
      paymentMethod: method,
      secret: secret,
      groupId: groupId ?? '',
      updatedAt: DateTime.now(),
    )).toList();

    try {
      await widget.syncService.updateSlots(updatedSlots);
      if (slots.isNotEmpty) {
        final label = slots.map((s) => s.id).join(', ');
        widget.onSyncMonitor(label, secret, groupId: groupId);
      }
      
      if (!mounted) return;
      widget.onCompleted?.call();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler beim Speichern: $e', isError: true));
      }
    }
  }

  Future<void> _updateAndPop(WardrobeSlot slot) async {
    try {
      await widget.syncService.updateSlot(slot);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler: $e', isError: true));
      }
    }
  }
}
