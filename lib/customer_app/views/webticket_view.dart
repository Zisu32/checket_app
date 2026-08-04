import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/platform_hints.dart';
import '../../shared/theme/brand_colors.dart';

class CustomerWebTicketView extends StatefulWidget {
  final int? ticketId;
  final String? secret;

  const CustomerWebTicketView({
    super.key,
    this.ticketId,
    this.secret,
    @Deprecated('Status is now fetched via SyncService') String? status,
  });

  @override
  State<CustomerWebTicketView> createState() => _CustomerWebTicketViewState();
}

class _CustomerWebTicketViewState extends State<CustomerWebTicketView> with TickerProviderStateMixin {
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

            Color statusColor = BrandColors.active;
            IconData statusIcon = Icons.verified_user_outlined;
            String statusText = 'Jacke auf Platz aktiv';
            bool isSearching = !snapshot.hasData;

            if (isSearching) {
              statusColor = BrandColors.white;
              statusIcon = Icons.sync;
              statusText = _showTimeoutMessage ? 'Wird synchronisiert...' : 'Ticket lädt...';
            } else if (slot == null) {
              statusColor = BrandColors.unpaid;
              statusIcon = Icons.error_outline;
              statusText = 'Ticket ungültig';
            } else {
              if (slot.status == 'unpaid') {
                statusColor = BrandColors.unpaid;
                statusIcon = Icons.credit_card_off_outlined;
                statusText = 'Zahlung ausstehend';
              } else if (slot.status == 'temporary') {
                statusColor = BrandColors.temporary;
                statusIcon = Icons.pause;
                statusText = 'Jacke temporär draußen';
              } else if (slot.status == 'forgotten') {
                statusColor = BrandColors.forgotten;
                statusIcon = Icons.inventory_2_outlined;
                statusText = 'Jacke im Fundbüro';
              } else if (slot.status == 'free') {
                statusColor = BrandColors.free;
                statusIcon = Icons.task_alt;
                statusText = 'Jacke bereits abgeholt';
                _clearPersistence();
              } else if (slot.status == 'picked_up') {
                statusColor = BrandColors.free;
                statusIcon = Icons.task_alt;
                statusText = 'Jacke bereits abgeholt';
                _clearPersistence();
              } else if (slot.status == 'wrong_secret') {
                statusColor = BrandColors.secret;
                statusIcon = Icons.lock_person_outlined;
                statusText = 'Secret stimmt nicht';
                _clearPersistence();
              }
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
                    errorBuilder: (context, error, stackTrace) => const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: BrandColors.white, fontSize: 14)),
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

                        // Main Ticket Card
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Container(
                                    padding: EdgeInsets.all(isShortScreen ? 20 : 32),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: BrandColors.shadow.withValues(
                                            alpha: (0.35 + _pulseAnimation.value * 0.65).clamp(0.0, 1.0),
                                          ),
                                          blurRadius: 45 * _pulseAnimation.value,
                                          spreadRadius: 10 * _pulseAnimation.value,
                                        ),
                                        BoxShadow(
                                          color: BrandColors.shadow.withValues(
                                            alpha: (0.5 + _pulseAnimation.value * 0.5).clamp(0.0, 1.0),
                                          ),
                                          blurRadius: 15 * _pulseAnimation.value,
                                          spreadRadius: 2 * _pulseAnimation.value,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isSearching)
                                          const CircularProgressIndicator(color: BrandColors.white)
                                        else ...[
                                          Icon(statusIcon, color: BrandColors.white, size: isShortScreen ? 48 : 64),
                                          SizedBox(height: isShortScreen ? 8 : 16),
                                          Text(statusText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: BrandColors.white)),
                                          const SizedBox(height: 12),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '$_activeId',
                                              style: TextStyle(
                                                fontSize: isShortScreen ? 80 : 110,
                                                fontWeight: FontWeight.w900,
                                                color: BrandColors.white,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // Weiße Linie, die um die Kachel wandert
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedBuilder(
                                    animation: _borderRotationController,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        painter: _SnakingBorderPainter(
                                          rotation: _borderRotationController.value * 2 * math.pi,
                                          borderRadius: 24,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Messaging
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(error, style: const TextStyle(color: BrandColors.unpaid, fontSize: 12), textAlign: TextAlign.center),
                          )
                        else if (slot != null && slot.status == 'wrong_secret')
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text('Jacke wurde abgeholt. Dieser Link ist nicht mehr gültig.',
                                style: TextStyle(color: BrandColors.free, fontSize: 12), textAlign: TextAlign.center),
                          )
                        else if (_showTimeoutMessage && isSearching)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  const Text('Wird synchronisiert...', style: TextStyle(color: BrandColors.free, fontSize: 12)),
                                  TextButton(onPressed: () => _syncService.pullFromSupabase(), child: const Text('Reload', style: TextStyle(color: BrandColors.active))),
                                ],
                              ),
                            ),

                        // Informations- und Aktionsbereich unter der Kachel
                        _buildInfoArea(slot, isShortScreen),

                        SizedBox(height: isShortScreen ? 12 : 24),
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

  Widget _buildInfoArea(WardrobeSlot? slot, bool isShort) {
    if (slot == null) return const SizedBox(height: 100);

    String text = '';
    Widget? extra;
    bool iconAbove = false;

    final isIOS = PlatformHints.isIOS;
    final walletName = isIOS ? 'Apple Wallet' : 'Google Wallet';

    switch (slot.status) {
      case 'unpaid':
        text = 'Bitte an das Lesegerät halten';
        extra = const Icon(Icons.contactless_outlined, color: BrandColors.active, size: 44);
        iconAbove = true;
        break;
      case 'active':
        text = 'Zur $walletName hinzufügen für Abholerinnerung.';
        extra = _buildBrandedWalletButton(isIOS);
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

  Widget _buildBrandedWalletButton(bool isIOS) {
    if (isIOS) {
      // Apple Wallet Style Badge
      return InkWell(
        onTap: _addToWallet,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wallet, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Add to Apple Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Google Wallet Style Button
      return InkWell(
        onTap: _addToWallet,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF5F6368)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wallet, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Add to Google Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _addToWallet() async {
    // Calling Supabase Edge Function to generate the pass
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen des Passes: $e'),
          backgroundColor: BrandColors.unpaid,
        ),
      );
    }
  }
}

class _SnakingBorderPainter extends CustomPainter {
  final double rotation;
  final double borderRadius;
  final double strokeWidth;

  _SnakingBorderPainter({
    required this.rotation,
    this.borderRadius = 24,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Colors.transparent,
          BrandColors.white,
          BrandColors.white,
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.28, 0.42],
        transform: GradientRotation(rotation),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SnakingBorderPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}