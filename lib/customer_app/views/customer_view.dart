import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/platform_hints_service.dart';
import '../../shared/theme/brand_colors.dart';
import '../widgets/ticket_card.dart';
import '../widgets/branded_wallet_button.dart';

class CustomerView extends StatefulWidget {
  final int? ticketId;
  final String? secret;

  const CustomerView({
    super.key,
    this.ticketId,
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

    if (widget.ticketId != null && widget.secret != null && widget.secret!.isNotEmpty) {
      _activeId = widget.ticketId;
      _activeSecret = widget.secret;
      storage.setItem('last_ticket_id', _activeId.toString());
      storage.setItem('last_ticket_secret', _activeSecret!);
    } else {
      final storedId = storage.getItem('last_ticket_id');
      final storedSecret = storage.getItem('last_ticket_secret');
      if (storedId != null && storedSecret != null) {
        _activeId = int.tryParse(storedId);
        _activeSecret = storedSecret;
      }
    }
  }

  void _clearPersistence() {
    final storage = web.window.localStorage;
    storage.removeItem('last_ticket_id');
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

    if (_activeId == null || _activeSecret == null) {
      return _buildNoTicketFoundUI();
    }

    return ValueListenableBuilder<String?>(
      valueListenable: _syncService.errorNotifier,
      builder: (context, error, _) {
        return StreamBuilder<WardrobeSlot?>(
          stream: _syncService.watchTicket(_activeId!, _activeSecret!),
          builder: (context, snapshot) {
            final slot = snapshot.data;
            final bool isSearching = !snapshot.hasData;
            
            final (statusColor, statusIcon, statusText) = switch (error) {
              String e when e.isNotEmpty => (
                BrandColors.secret,
                Icons.cloud_off_outlined,
                'Verbindungsfehler...'
              ),
              _ => switch (slot) {
                _ when isSearching => (
                  BrandColors.white,
                  Icons.sync,
                  _showTimeoutMessage ? 'Wird synchronisiert...' : 'Ticket lädt...'
                ),
                null => (
                  BrandColors.unpaid,
                  Icons.error_outline,
                  'Ticket ungültig'
                ),
                _ => switch (slot.status) {
                  'unpaid' => (BrandColors.unpaid, Icons.credit_card_off_outlined, 'Zahlung ausstehend'),
                  'temporary' => (BrandColors.temporary, Icons.pause, 'Jacke temporär draußen'),
                  'forgotten' => (BrandColors.forgotten, Icons.inventory_2_outlined, 'Jacke im Fundbüro'),
                  'free' || 'picked_up' => (BrandColors.free, Icons.task_alt, 'Jacke bereits abgeholt'),
                  'wrong_secret' => (BrandColors.secret, Icons.lock_person_outlined, 'Secret stimmt nicht'),
                  _ => (BrandColors.active, Icons.verified_user_outlined, 'Jacke auf Platz aktiv'),
                },
              },
            };

            if (slot != null && ['free', 'picked_up', 'wrong_secret'].contains(slot.status)) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _clearPersistence());
            }

            return Scaffold(
              backgroundColor: BrandColors.background,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: AppBar(
                  backgroundColor: BrandColors.header,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  centerTitle: true,
                  title: Image.asset(
                    'assets/images/full-icon.png',
                    height: 28,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'CHECKET',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: BrandColors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isShortScreen ? 12 : 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isShortScreen ? 12 : 20),

                        TicketCard(
                          statusColor: statusColor,
                          statusIcon: statusIcon,
                          statusText: statusText,
                          ticketId: _activeId!,
                          isSearching: isSearching && error == null,
                          isShortScreen: isShortScreen,
                          pulseAnimation: _pulseAnimation,
                          borderRotationController: _borderRotationController,
                        ),

                        const Spacer(),
                        _buildInfoArea(slot, isShortScreen),
                      ],
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

  Widget _buildNoTicketFoundUI() {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/full-icon.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const Text('CHECKET',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: BrandColors.white))),
              const SizedBox(height: 40),
              const Icon(Icons.search_off, color: BrandColors.free, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Kein aktives Ticket gefunden',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BrandColors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bitte scanne den QR-Code oder wende dich an das Personal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BrandColors.free, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoArea(WardrobeSlot? slot, bool isShort) {
    if (slot == null) return const SizedBox(height: 100);

    String text = '';
    Widget? extra;
    bool iconAbove = false;

    final isIOS = PlatformHints.isIOS;

    switch (slot.status) {
      case 'unpaid':
        text = 'Bitte an das Lesegerät halten';
        extra = _buildPayWithPhoneIcon();
        iconAbove = true;
        break;
      case 'active':
        text = 'für Abholerinnerung der Jacke';
        extra = Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: BrandedWalletButton(isIOS: isIOS, onTap: _addToWallet),
        );
        iconAbove = true;
        break;
      case 'temporary':
        text = 'Jacke wieder einchecken';
        break;
      case 'forgotten':
        text = 'Jacke kann im Fundbüro abgeholt werden';
        break;
      case 'free':
      case 'picked_up':
      case 'wrong_secret':
        text = 'Sie können die Seite schließen';
        break;
      default:
        return const SizedBox(height: 100);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (extra != null && iconAbove) ...[
            extra,
            const SizedBox(height: 12),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BrandColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (extra != null && !iconAbove) ...[
            const SizedBox(height: 16),
            extra,
          ],
        ],
      ),
    );
  }

  Widget _buildPayWithPhoneIcon() {
    return SvgPicture.asset(
      'assets/images/pay_with_phone.svg',
      height: 50,
    );
  }

  Future<void> _addToWallet() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'generate-wallet-pass',
        body: {
          'ticketId': _activeId,
          'secret': _activeSecret,
          'platform': PlatformHints.isIOS ? 'apple' : 'google',
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
        SnackBar(
          content: Text('Fehler beim Erstellen des Passes: $e'),
          backgroundColor: BrandColors.unpaid,
        ),
      );
    }
  }
}
