import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/brand_colors.dart';

class CustomerWebTicketView extends StatefulWidget {
  final int ticketId;
  final String secret;
  
  const CustomerWebTicketView({
    super.key, 
    required this.ticketId, 
    required this.secret,
    @Deprecated('Status is now fetched via SyncService') String? status,
  });

  @override
  State<CustomerWebTicketView> createState() => _CustomerWebTicketViewState();
}

class _CustomerWebTicketViewState extends State<CustomerWebTicketView> with SingleTickerProviderStateMixin {
  bool _hatBerechtigungGefragt = false;
  final _syncService = SyncService();
  bool _showTimeoutMessage = false;
  Timer? _timeoutTimer;
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final permission = web.Notification.permission;
    if (permission == 'granted' || permission == 'denied') {
      _hatBerechtigungGefragt = true;
    }
    
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
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _frageNachPush() async {
    await web.Notification.requestPermission().toDart;
    setState(() { _hatBerechtigungGefragt = true; });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isShortScreen = screenHeight < 700;

    return ValueListenableBuilder<String?>(
      valueListenable: _syncService.errorNotifier,
      builder: (context, error, _) {
        return StreamBuilder<WardrobeSlot?>(
          stream: _syncService.watchTicket(widget.ticketId, widget.secret),
          builder: (context, snapshot) {
            final slot = snapshot.data;
            
            Color statusFarbe = BrandColors.active; 
            IconData statusIcon = Icons.verified_user_outlined; 
            String statusText = 'Garderoben-Platz aktiv';
            bool isSearching = !snapshot.hasData;

            if (isSearching) {
              statusFarbe = Colors.white24;
              statusIcon = Icons.sync;
              statusText = _showTimeoutMessage ? 'Wird synchronisiert...' : 'Ticket lädt...';
            } else if (slot == null) {
              statusFarbe = BrandColors.unpaid;
              statusIcon = Icons.error_outline;
              statusText = 'Ticket ungültig';
            } else {
              if (slot.status == 'unpaid') { 
                statusFarbe = BrandColors.unpaid; 
                statusIcon = Icons.credit_card_off_outlined; 
                statusText = 'Zahlung ausstehend'; 
              } else if (slot.status == 'temporary') { 
                statusFarbe = BrandColors.temporary; 
                statusIcon = Icons.timer_outlined; 
                statusText = 'Jacke temporär draußen'; 
              } else if (slot.status == 'forgotten') { 
                statusFarbe = BrandColors.forgotten; 
                statusIcon = Icons.inventory_2_outlined; 
                statusText = 'Jacke im Fundbüro'; 
              } else if (slot.status == 'free') {
                statusFarbe = BrandColors.free;
                statusIcon = Icons.check_circle_outline;
                statusText = 'Bügel frei';
              } else if (slot.status == 'picked_up') {
                statusFarbe = BrandColors.free; 
                statusIcon = Icons.task_alt;
                statusText = 'Jacke bereits abgeholt';
              } else if (slot.status == 'wrong_secret') {
                statusFarbe = BrandColors.free;
                statusIcon = Icons.lock_person_outlined;
                statusText = 'Bügel frei';
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
                  ),
                ),
              ),
              body: SafeArea(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400), 
                    padding: EdgeInsets.symmetric(
                      horizontal: 24, 
                      vertical: isShortScreen ? 12 : 24
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isShortScreen ? 12 : 20),

                        // Main Ticket Card
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity, 
                              padding: EdgeInsets.all(isShortScreen ? 20 : 32),
                              decoration: BoxDecoration(
                                color: BrandColors.surface, 
                                borderRadius: BorderRadius.circular(24), 
                                border: Border.all(
                                  color: statusFarbe.withValues(alpha: _pulseAnimation.value), 
                                  width: 5.0
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusFarbe.withValues(alpha: _pulseAnimation.value * 0.4),
                                    blurRadius: 25 * _pulseAnimation.value,
                                    spreadRadius: 4 * _pulseAnimation.value,
                                  )
                                ]
                              ),
                              child: Column(
                                children: [
                                  if (isSearching)
                                    const CircularProgressIndicator(color: Colors.white24)
                                  else ...[
                                    Icon(statusIcon, color: statusFarbe, size: isShortScreen ? 48 : 64),
                                    SizedBox(height: isShortScreen ? 8 : 16),
                                    Text(statusText, textAlign: TextAlign.center, style: TextStyle(fontSize: isShortScreen ? 16 : 18, fontWeight: FontWeight.w500, color: Colors.white)),
                                    SizedBox(height: isShortScreen ? 12 : 24),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${widget.ticketId}', 
                                        style: TextStyle(
                                          fontSize: isShortScreen ? 80 : 110, 
                                          fontWeight: FontWeight.w900, 
                                          color: statusFarbe, 
                                          height: 1
                                        )
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            );
                          },
                        ),
                        
                        const Spacer(),

                        // Error or Messaging
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                          )
                        else if (slot != null && slot.status == 'wrong_secret')
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text('Jacke wurde abgeholt. Dieser Link ist nicht mehr gültig.', 
                                 style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                          )
                        else if (_showTimeoutMessage && isSearching)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                const Text('Wird synchronisiert...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                TextButton(onPressed: () => _syncService.pullFromSupabase(), child: const Text('Reload', style: TextStyle(color: BrandColors.active)))
                              ],
                            ),
                          ),

                        // Actions
                        if (slot != null && slot.status == 'active' && !_hatBerechtigungGefragt) 
                          _bauePushPrompt(isShortScreen),
                        
                        if (slot != null && slot.status == 'unpaid') 
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandColors.active, 
                              foregroundColor: Colors.white, 
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ), 
                            onPressed: () {}, 
                            child: const Text('JETZT BEZAHLEN', style: TextStyle(fontWeight: FontWeight.bold))
                          )
                        else if (slot != null && slot.status != 'free' && slot.status != 'picked_up' && slot.status != 'loading' && slot.status != 'wrong_secret') 
                          Column(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black, 
                                  foregroundColor: Colors.white, 
                                  minimumSize: const Size(double.infinity, 44),
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ), 
                                icon: const Icon(Icons.add_to_home_screen, size: 20), 
                                label: const Text('Apple Wallet'), 
                                onPressed: () => web.window.open('https://deine-garderobe.de/${widget.ticketId}&secret=${widget.secret}', '_blank')
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4285F4), 
                                  foregroundColor: Colors.white, 
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ), 
                                icon: const Icon(Icons.account_balance_wallet, size: 20), 
                                label: const Text('Google Wallet'), 
                                onPressed: () => web.window.open('https://deine-garderobe.de/${widget.ticketId}&secret=${widget.secret}', '_blank')
                              ),
                            ],
                          )
                        else const SizedBox(height: 100),
                        
                        SizedBox(height: isShortScreen ? 12 : 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _bauePushPrompt(bool isShort) {
    return Container(
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Jacke am Ende nicht vergessen! 🧥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          SizedBox(height: isShort ? 4 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end, 
            children: [
              TextButton(onPressed: () => setState(() => _hatBerechtigungGefragt = true), child: const Text('Nein')), 
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.active),
                onPressed: _frageNachPush, 
                child: const Text('Ja, gerne', style: TextStyle(color: Colors.white))
              )
            ]
          )
        ],
      ),
    );
  }
}
