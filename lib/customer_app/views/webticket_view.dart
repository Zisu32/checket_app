import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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

                        // Actions
                        if (slot != null && slot.status == 'active')
                          _bauWalletHinweis(isShortScreen),

                        if (slot != null && (slot.status == 'free' || slot.status == 'picked_up'))
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                              'Seite kann geschlossen werden',
                              style: TextStyle(color: BrandColors.free, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else if (slot != null && slot.status != 'loading')
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                              'Bitte zeige dieses Ticket beim Abholen vor.',
                              style: TextStyle(color: BrandColors.free, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          const SizedBox(height: 100),

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

  Widget _buildNoTicketFoundUI() {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/full-icon.png', height: 60, errorBuilder: (context, error, stackTrace) => const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: BrandColors.white))),
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

  Widget _bauWalletHinweis(bool isShort) {
    final walletName = PlatformHints.isIOS ? 'Apple Wallet' : 'Google Wallet';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(color: BrandColors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Zur $walletName hinzufügen, um benachrichtigt zu werden, falls die Jacke vergessen wurde.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: BrandColors.white),
          ),
          SizedBox(height: isShort ? 8 : 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.header),
            onPressed: _addToWallet,
            icon: const Icon(Icons.wallet, size: 18),
            label: Text('Zu $walletName hinzufügen', style: const TextStyle(color: BrandColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addToWallet() async {
    // Noch nicht angebunden. Erfordert ein eigenes Backend:
    // – Apple: PassKit-Web-Service + signiertes .pkpass (Pass-Type-Zertifikat nötig)
    // – Android: Google Wallet API + signiertes "Save to Google Wallet"-JWT
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet-Integration wird noch vorbereitet.')),
    );
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