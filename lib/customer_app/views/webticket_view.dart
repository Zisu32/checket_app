import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
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

class _CustomerWebTicketViewState extends State<CustomerWebTicketView> {
  bool _hatBerechtigungGefragt = false;
  final _syncService = SyncService();
  bool _showTimeoutMessage = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    if (html.Notification.permission == 'granted' || html.Notification.permission == 'denied') {
      _hatBerechtigungGefragt = true;
    }
    
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showTimeoutMessage = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _frageNachPush() async {
    await html.Notification.requestPermission();
    setState(() { _hatBerechtigungGefragt = true; });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WardrobeSlot>>(
      stream: _syncService.watchSlots(),
      builder: (context, snapshot) {
        final slots = snapshot.data ?? [];
        
        // Find the specific slot for this ticket
        final slot = slots.firstWhere(
          (s) => s.id == widget.ticketId, 
          orElse: () => WardrobeSlot(
            id: widget.ticketId, 
            updatedAt: DateTime.now(), 
            status: 'loading',
            isPaid: false,
            paymentMethod: 'none',
            secret: '',
          )
        );

        Color statusFarbe = Colors.greenAccent; 
        IconData statusIcon = Icons.verified_user_outlined; 
        String statusText = 'Garderoben-Platz aktiv';

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
        } else if (slot.status == 'loading') {
          statusFarbe = Colors.white24;
          statusIcon = Icons.sync;
          statusText = _showTimeoutMessage ? 'Verbindung wird gesucht...' : 'Ticket lädt...';
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
                  const Text('CHECKET - DIGITAL TICKET', style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A), 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: statusFarbe.withValues(alpha: 0.3), width: 2)
                    ),
                    child: Column(
                      children: [
                        if (slot.status == 'loading')
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
                  ),
                  
                  if (_showTimeoutMessage && slot.status == 'loading')
                    const Text('Die Synchronisierung dauert lange. Bitte prüfen Sie Ihre Internetverbindung.', 
                         style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),

                  if (slot.status == 'active' && !_hatBerechtigungGefragt) _bauePushPrompt(),
                  if (slot.status == 'unpaid') 
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, 
                        foregroundColor: Colors.black, 
                        minimumSize: const Size(double.infinity, 50)
                      ), 
                      onPressed: () {
                        // Stripe call will be implemented here
                      }, 
                      child: const Text('Jetzt bezahlen')
                    )
                  else if (slot.status != 'loading') Column(children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)), 
                      icon: const Icon(Icons.add_to_home_screen), 
                      label: const Text('Zu Apple Wallet hinzufügen'), 
                      onPressed: () => html.window.open('https://deine-garderobe.de/${widget.ticketId}&secret=${widget.secret}', '_blank')
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)), 
                      icon: const Icon(Icons.account_balance_wallet), 
                      label: const Text('Zu Google Wallet hinzufügen'), 
                      onPressed: () => html.window.open('https://deine-garderobe.de/${widget.ticketId}&secret=${widget.secret}', '_blank')
                    ),
                  ])
                  else const SizedBox(height: 100), // Spacer for loading state
                ],
              ),
            ),
          ),
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
