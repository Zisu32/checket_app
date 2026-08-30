import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/platform_hints_service.dart';
import '../../shared/theme/app_theme.dart';
import '../widgets/ticket_card.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../widgets/ticket_info_area.dart';
import '../widgets/no_ticket.dart';

class CustomerView extends StatefulWidget {
  final int? ticketId;
  final String? groupId;
  final String? secret;

  const CustomerView({
    super.key,
    this.ticketId,
    this.groupId,
    this.secret,
    @Deprecated('Status is now fetched via SyncService') String? status,
  });

  @override
  State<CustomerView> createState() => _CustomerViewState();
}

class _CustomerViewState extends State<CustomerView> with TickerProviderStateMixin {
  final _syncService = SyncService();
  bool _showTimeoutMessage = false;
  Timer? _timeoutTimer;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _borderRotationController;

  int? _activeId;
  String? _activeGroupId;
  String? _activeSecret;

  @override
  void initState() {
    super.initState();
    _handlePersistence();

    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showTimeoutMessage = true);
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _borderRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _handlePersistence() {
    final storage = web.window.localStorage;

    if ((widget.ticketId != null || widget.groupId != null) && widget.secret != null && widget.secret!.isNotEmpty) {
      _activeId = widget.ticketId;
      _activeGroupId = widget.groupId;
      _activeSecret = widget.secret;
      if (_activeId != null) storage.setItem('last_ticket_id', _activeId.toString());
      if (_activeGroupId != null) storage.setItem('last_group_id', _activeGroupId!);
      storage.setItem('last_ticket_secret', _activeSecret!);
    } else {
      final storedId = storage.getItem('last_ticket_id');
      final storedGroupId = storage.getItem('last_group_id');
      final storedSecret = storage.getItem('last_ticket_secret');
      if (storedSecret != null) {
        _activeId = storedId != null ? int.tryParse(storedId) : null;
        _activeGroupId = storedGroupId;
        _activeSecret = storedSecret;
      }
    }
  }

  void _clearPersistence() {
    final storage = web.window.localStorage;
    storage.removeItem('last_ticket_id');
    storage.removeItem('last_group_id');
    storage.removeItem('last_ticket_secret');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animationController.dispose();
    _borderRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isShortScreen = screenHeight < 700;

    if ((_activeId == null && _activeGroupId == null) || _activeSecret == null) {
      return const NoTicket();
    }

    return ValueListenableBuilder<String?>(
      valueListenable: _syncService.errorNotifier,
      builder: (context, error, _) {
        return StreamBuilder<List<WardrobeSlot>>(
          stream: _activeGroupId != null 
              ? _syncService.watchGroup(_activeGroupId!, _activeSecret!)
              : _syncService.watchTicket(_activeId!, _activeSecret!).map((s) => s != null ? [s] : []),
          builder: (context, snapshot) {
            final slots = snapshot.data ?? [];
            final bool isSearching = !snapshot.hasData;
            
            if (slots.isEmpty && !isSearching) {
               return const NoTicket();
            }

            final isAllGone = slots.isNotEmpty && slots.every((s) => ['free', 'picked_up', 'wrong_secret'].contains(s.status));
            if (isAllGone) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _clearPersistence());
            }

            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: AppBar(
                  backgroundColor: AppTheme.header,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  centerTitle: true,
                  title: SvgPicture.asset(
                    'assets/images/full-icon.svg',
                    height: 28,
                  ),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          ...slots.map((slot) {
                            final (statusColor, statusIcon, statusText) = _getStatusInfo(slot, error);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: TicketCard(
                                statusColor: statusColor,
                                statusIcon: statusIcon,
                                statusText: statusText,
                                ticketId: slot.id,
                                isSearching: isSearching && error == null,
                                isShortScreen: isShortScreen,
                                pulseAnimation: _pulseAnimation,
                                borderRotationController: _borderRotationController,
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                          TicketInfoArea(
                            slot: slots.isNotEmpty ? slots.first : null,
                            isShort: isShortScreen,
                            onAddToWallet: _addToWallet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  (Color, IconData, String) _getStatusInfo(WardrobeSlot? slot, String? error) {
    if (error != null && error.isNotEmpty) {
      return (AppTheme.secret, Icons.cloud_off_outlined, 'Verbindungsfehler...');
    }
    
    if (slot == null) {
      return (AppTheme.unpaid, Icons.error_outline, 'Ticket ungültig');
    }

    return switch (slot.status) {
      'unpaid' => (AppTheme.unpaid, Icons.credit_card_off_outlined, 'Zahlung ausstehend'),
      'temporary' => (AppTheme.temporary, Icons.pause, 'Jacke temporär draußen'),
      'forgotten' => (AppTheme.forgotten, Icons.inventory_2_outlined, 'Jacke im Fundbüro'),
      'free' || 'picked_up' => (AppTheme.free, Icons.task_alt, 'Jacke bereits abgeholt'),
      'wrong_secret' => (AppTheme.secret, Icons.lock_person_outlined, 'Secret stimmt nicht'),
      'marked' => (AppTheme.temporary, Icons.timer_outlined, 'Wird bearbeitet...'),
      _ => (AppTheme.active, Icons.verified_user_outlined, 'Jacke auf Platz aktiv'),
    };
  }

  Future<void> _addToWallet() async {
    try {
      final supabase = Supabase.instance.client;
      // Send the current origin so the backend can generate correct links for dev/prod
      final origin = web.window.location.origin;
      final path = web.window.location.pathname;
      final tenant = _syncService.schemaName;

      final response = await supabase.functions.invoke(
        'generate-wallet-pass',
        body: {
          'ticketId': _activeId,
          'groupId': _activeGroupId,
          'secret': _activeSecret,
          'platform': PlatformHintsService.isIOS ? 'apple' : 'google',
          'origin': '$origin$path',
          'tenant': tenant,
        },
      );

      final url = response.data['url'] as String?;
      if (url != null && url.isNotEmpty) {
        web.window.open(url, '_blank');
      } else {
        throw 'Ungültige Antwort vom Server.';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(message: 'Fehler beim Erstellen des Passes: $e', isError: true),
      );
    }
  }
}
