import 'package:flutter/material.dart';
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/sumup_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/app_action_sheet.dart';

class WardrobeActionSheet extends StatefulWidget {
  final WardrobeSlot initialSlot;
  final SyncService syncService;
  final Function(int id, String secret) onSyncMonitor;
  final String Function() onGenerateSecret;

  const WardrobeActionSheet({
    super.key,
    required this.initialSlot,
    required this.syncService,
    required this.onSyncMonitor,
    required this.onGenerateSecret,
  });

  @override
  State<WardrobeActionSheet> createState() => _WardrobeActionSheetState();
}

class _WardrobeActionSheetState extends State<WardrobeActionSheet> {
  bool _isProcessingSumUp = false;
  String _sumUpStatusText = 'Warte auf Terminal...';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WardrobeSlot>>(
      stream: widget.syncService.watchSlots(),
      builder: (context, snapshot) {
        final slots = snapshot.data ?? [];
        final slot = slots.firstWhere((s) => s.id == widget.initialSlot.id, orElse: () => widget.initialSlot);

        return AppActionSheet(
          title: 'Bügel ${slot.id}',
          subtitle: _getStatusLabel(slot.status),
          actions: _buildActions(slot),
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
      default: return '';
    }
  }

  List<SheetAction> _buildActions(WardrobeSlot slot) {
    final actions = <SheetAction>[];

    if (slot.status == 'free') {
      actions.add(SheetAction(
        icon: Icons.add_box,
        label: 'Jacke einchecken',
        color: AppTheme.active,
        onTap: () async {
          final secret = widget.onGenerateSecret();
          final updated = slot.copyWith(
            status: 'unpaid',
            secret: secret,
            isPaid: false,
            paymentMethod: 'none',
            updatedAt: DateTime.now(),
          );
          widget.onSyncMonitor(slot.id, secret);
          await widget.syncService.updateSlot(updated);
        },
      ));
    }

    if (slot.status == 'unpaid') {
      actions.add(SheetAction(
        leading: _isProcessingSumUp 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.active))
            : const Icon(Icons.contactless_outlined, color: AppTheme.active),
        label: _isProcessingSumUp ? _sumUpStatusText : 'Kontaktloses bezahlen',
        color: AppTheme.active,
        onTap: _isProcessingSumUp ? null : () async {
          setState(() {
            _isProcessingSumUp = true;
            _sumUpStatusText = 'Warte auf Terminal...';
          });
          
          try {
            final checkoutId = await SumUpService().triggerTerminalPayment(
              slotId: slot.id,
              secret: slot.secret,
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
                  final updated = slot.copyWith(
                    status: 'active', 
                    isPaid: true, 
                    paymentMethod: 'nfc', 
                    updatedAt: DateTime.now()
                  );
                  await widget.syncService.updateSlot(updated);
                  if (!mounted) return;
                  Navigator.pop(context);
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
            ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler: $e'));
          } finally {
            if (mounted) setState(() => _isProcessingSumUp = false);
          }
        },
      ));

      actions.add(SheetAction(
        icon: Icons.euro,
        label: 'Bar bezahlen',
        color: AppTheme.secret,
        onTap: () async {
          final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'bar', updatedAt: DateTime.now());
          await widget.syncService.updateSlot(updated);
          if (!mounted) return;
          Navigator.pop(context);
        },
      ));
    }

    if (slot.status == 'active' || slot.status == 'temporary') {
      if (slot.status == 'active') {
        actions.add(SheetAction(
          icon: Icons.pause,
          label: 'Temporärer Ausgang',
          color: AppTheme.temporary,
          onTap: () async {
            final updated = slot.copyWith(status: 'temporary', updatedAt: DateTime.now());
            await widget.syncService.updateSlot(updated);
            if (!mounted) return;
            Navigator.pop(context);
          },
        ));
      } else {
        actions.add(SheetAction(
          icon: Icons.play_arrow,
          label: 'Wieder zurück',
          color: AppTheme.active,
          onTap: () async {
            final updated = slot.copyWith(status: 'active', updatedAt: DateTime.now());
            await widget.syncService.updateSlot(updated);
            if (!mounted) return;
            Navigator.pop(context);
          },
        ));
      }

      actions.add(SheetAction(
        icon: Icons.logout,
        label: 'Endgültig auschecken',
        color: AppTheme.free,
        onTap: () async {
          final updated = slot.copyWith(
            status: 'free',
            isPaid: false,
            secret: '',
            paymentMethod: 'none',
            updatedAt: DateTime.now(),
          );
          await widget.syncService.updateSlot(updated);
          if (!mounted) return;
          Navigator.pop(context);
        },
      ));
    }

    return actions;
  }
}
