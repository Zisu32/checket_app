import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app/views/webticket_view.dart';
import 'shared/services/sync_service.dart';
import 'package:web/web.dart' as web;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activate Hash-Routing for GitHub Pages stability
  usePathUrlStrategy();

  // Initialize Supabase with environment variables (injected by GitHub Actions)
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://dtvozyjaljzptarkyzgo.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_pfzZGNSHyrnIZ-tfdrGvfw_50HpC1U2'),
  );

  // Initialize Sync Service (Drift & Supabase)
  await SyncService().init();

  runApp(const ChecketCustomerWebApp());
}

class ChecketCustomerWebApp extends StatelessWidget {
  const ChecketCustomerWebApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(web.window.location.href);
    
    String ticketId = uri.queryParameters['id'] ?? '';
    String secret = uri.queryParameters['secret'] ?? '';

    // Simple fallback to localStorage for PWA behavior
    if (ticketId.isEmpty || secret.isEmpty) {
      ticketId = web.window.localStorage.getItem('last_ticket_id') ?? '';
      secret = web.window.localStorage.getItem('last_ticket_secret') ?? '';
    } else {
      web.window.localStorage.setItem('last_ticket_id', ticketId);
      web.window.localStorage.setItem('last_ticket_secret', secret);
    }

    if (ticketId.isEmpty) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: Text('Kein aktives Ticket gefunden.'))),
        debugShowCheckedModeBanner: false,
      );
    }
    
    return MaterialApp(
      title: 'Checket Ticket',
      theme: ThemeData.dark(),
      home: CustomerWebTicketView(
        ticketId: int.parse(ticketId), 
        secret: secret
      ),
      debugShowCheckedModeBanner: false
    );
  }
}
