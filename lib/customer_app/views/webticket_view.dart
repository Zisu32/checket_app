import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';

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
    // Notification.permission returns a JSString in package:web
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
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.5).animate(
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
    return ValueListenableBuilder<String?>(
      valueListenable: _syncService.errorNotifier,
      builder: (context, error, _) {
        return StreamBuilder<List<WardrobeSlot>>(
          stream: _syncService.watchSlots(),
          builder: (context, snapshot) {
            final slots = snapshot.data ?? [];
            
            // Try to find the specific slot
            WardrobeSlot? slot;
            try {
              slot = slots.firstWhere((s) => s.id == widget.ticketId);
            } catch (_) {
              slot = null;
            }

            Color statusFarbe = Colors.greenAccent; 
            IconData statusIcon = Icons.verified_user_outlined; 
            String statusText = 'Garderoben-Platz aktiv';
            bool isLoading = slots.isEmpty || slot == null;

            if (isLoading) {
              statusFarbe = Colors.white24;
              statusIcon = Icons.sync;
              statusText = _showTimeoutMessage ? 'Wird synchronisiert...' : 'Ticket lädt...';
            } else {
              if (slot.status == 'unpaid') { 
                statusFarbe = Colors.redAccent; 
                statusIcon = Icons.credit_card_off_outlined; 
                statusText = 'Zahlung ausstehend'; 
              } else if (slot.status == 'temporary') { 
                statusFarbe = Colors.orangeAccent; 
                statusIcon = Icons.timer_outlined; 
                statusText = 'Jacke temporär draußen'; 
              } else if (slot.status == 'forgotten') { 
                statusFarbe = Colors.grey; 
                statusIcon = Icons.inventory_2_outlined; 
                statusText = 'Jacke im Fundbüro'; 
              } else if (slot.status == 'free') {
                statusFarbe = Colors.white24;
                statusIcon = Icons.check_circle_outline;
                statusText = 'Bügel wieder frei';
              }
            }

            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400), 
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withValues(alpha: _pulseAnimation.value * 2),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text('LIVE TICKET', style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: double.infinity, 
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A), 
                              borderRadius: BorderRadius.circular(24), 
                              border: Border.all(
                                color: statusFarbe.withValues(alpha: _pulseAnimation.value), 
                                width: 3
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusFarbe.withValues(alpha: _pulseAnimation.value * 0.5),
                                  blurRadius: 15 * _pulseAnimation.value,
                                  spreadRadius: 2 * _pulseAnimation.value,
                                )
                              ]
                            ),
                            child: Column(
                              children: [
                                if (isLoading)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(color: Colors.white24),
                                  )
                                else
                                  Icon(statusIcon, color: statusFarbe, size: 64),
                                const SizedBox(height: 16),
                                Text(statusText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 24),
                                Text('${widget.ticketId}', style: TextStyle(fontSize: 110, fontWeight: FontWeight.w900, color: statusFarbe, height: 1)),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      if (error != null)
                        Text(error, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center)
                      else if (_showTimeoutMessage && isLoading)
                        Column(
                          children: [
                            const Text('Das Ticket wurde noch nicht in der Datenbank gefunden.', 
                                 style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                            TextButton(onPressed: () => _syncService.pullFromSupabase(), child: const Text('Erneut versuchen'))
                          ],
                        ),

                      if (!isLoading && slot.status == 'active' && !_hatBerechtigungGefragt) _bauePushPrompt(),
                      
                      if (!isLoading && slot.status == 'unpaid') 
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: Colors.black, 
                            minimumSize: const Size(double.infinity, 50)
                          ), 
                          onPressed: () {}, 
                          child: const Text('Jetzt bezahlen')
                        )
                      else if (!isLoading && slot.status != 'free') Column(children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)), 
                          icon: const Icon(Icons.add_to_home_screen), 
                          label: const Text('Zu Apple Wallet hinzufügen'), 
                          onPressed: () => web.window.open('https://deine-garderobe.de/${widget.ticketId}&secret=${widget.secret}', '_blank')
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)), 
                          icon: const Icon(Icons.account_balance_wallet), 
                          label: const Text('Zu Google Wallet hinzufügen'), 
                          onPressed: () => web.window.open('https://deine-garderobe.de/${widget.ticketId}&secret=${widget.secret}', '_blank')
                        ),
                      ])
                      else const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _bauePushPrompt() {
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('Jacke am Ende nicht vergessen! 🧥', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end, 
            children: [
              TextButton(onPressed: () => setState(() => _hatBerechtigungGefragt = true), child: const Text('Nein')), 
              ElevatedButton(onPressed: _frageNachPush, child: const Text('Ja, gerne'))
            ]
          )
        ],
      ),
    );
  }
}
