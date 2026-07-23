import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class CustomerWebTicketView extends StatefulWidget {
  final int ticketId; final String status; final String secret;
  const CustomerWebTicketView({super.key, required this.ticketId, required this.status, required this.secret});
  @override
  State<CustomerWebTicketView> createState() => _CustomerWebTicketViewState();
}

class _CustomerWebTicketViewState extends State<CustomerWebTicketView> {
  bool _hatBerechtigungGefragt = false;

  @override
  void initState() {
    super.initState();
    if (html.Notification.permission == 'granted' || html.Notification.permission == 'denied') _hatBerechtigungGefragt = true;
  }

  Future<void> _frageNachPush() async {
    await html.Notification.requestPermission();
    setState(() { _hatBerechtigungGefragt = true; });
  }

  @override
  Widget build(BuildContext context) {
    Color statusFarbe = Colors.greenAccent; IconData statusIcon = Icons.verified_user_outlined; String statusText = 'Garderoben-Platz aktiv';
    if (widget.status == 'unpaid') { statusFarbe = Colors.redAccent; statusIcon = Icons.credit_card_off_outlined; statusText = 'Zahlung ausstehend'; }
    else if (widget.status == 'temporary') { statusFarbe = Colors.orangeAccent; statusIcon = Icons.timer_outlined; statusText = 'Jacke temporär draußen'; }
    else if (widget.status == 'forgotten') { statusFarbe = Colors.grey; statusIcon = Icons.inventory_2_outlined; statusText = 'Jacke im Fundbüro'; }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CHECKET - DIGITAL TICKET', style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold)),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(24), border: Border.all(color: statusFarbe.withValues(alpha: 0.3), width: 2)),
                child: Column(
                  children: [
                    Icon(statusIcon, color: statusFarbe, size: 64),
                    const SizedBox(height: 16),
                    Text(statusText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    Text('${widget.ticketId}', style: TextStyle(fontSize: 110, fontWeight: FontWeight.black, color: statusFarbe, height: 1)),
                  ],
                ),
              ),
              if (widget.status == 'active' && !_hatBerechtigungGefragt) _bauePushPrompt(),
              if (widget.status == 'unpaid') ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)), onPressed: () {}, child: const Text('Jetzt bezahlen'))
              else Column(children: [
                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)), icon: const Icon(Icons.add_to_home_screen), label: const Text('Zu Apple Wallet hinzufügen'), onPressed: () => html.window.open('https://deine-garderobe.de{widget.ticketId}&secret=${widget.secret}', '_blank')),
                const SizedBox(height: 8),
                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)), icon: const Icon(Icons.google), label: const Text('Zu Google Wallet hinzufügen'), onPressed: () => html.window.open('https://deine-garderobe.de{widget.ticketId}&secret=${widget.secret}', '_blank')),
              ])
            ],
          ),
        ),
      ),
    );
  }

  Widget _bauePushPrompt() {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white05, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('Jacke am Ende nicht vergessen! 🧥', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => setState(() => _hatBerechtigungGefragt = true), child: const Text('Nein')), ElevatedButton(onPressed: _frageNachPush, child: const Text('Ja, gerne'))])
        ],
      ),
    );
  }
}
