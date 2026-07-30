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
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Initialize Sync Service (Drift & Supabase) with unique name
  await SyncService().init(dbName: 'checket_customer_db');

  runApp(const ChecketCustomerWebApp());
}

class ChecketCustomerWebApp extends StatelessWidget {
  const ChecketCustomerWebApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Robust URL parsing for GitHub Pages
    final fullUrl = web.window.location.href;
    final uri = Uri.parse(fullUrl);
    
    // Check both standard query parameters AND hash parameters
    Map<String, String> params = Map.from(uri.queryParameters);
    
    // If we are using hash routing, parameters might be in the fragment
    if (uri.hasFragment) {
      final fragmentUri = Uri.parse(uri.fragment);
      params.addAll(fragmentUri.queryParameters);
    }

    String ticketId = params['id'] ?? '';
    String secret = params['secret'] ?? '';

    print('Sync: URL detected -> $fullUrl');
    print('Sync: Extracted Params -> id: $ticketId, secret: $secret');

    // Simple fallback to localStorage for PWA behavior
    if (ticketId.isEmpty || secret.isEmpty) {
      ticketId = web.window.localStorage.getItem('last_ticket_id') ?? '';
      secret = web.window.localStorage.getItem('last_ticket_secret') ?? '';
      print('Sync: Fallback to localStorage -> id: $ticketId');
    } else {
      web.window.localStorage.setItem('last_ticket_id', ticketId);
      web.window.localStorage.setItem('last_ticket_secret', secret);
    }

    final ticketIdInt = int.tryParse(ticketId);

    if (ticketIdInt == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: Text('Kein aktives Ticket gefunden.'))),
        debugShowCheckedModeBanner: false,
      );
    }
    
    return MaterialApp(
      title: 'Checket Ticket',
      theme: ThemeData.dark(),
      home: CustomerWebTicketView(
        ticketId: ticketIdInt, 
        secret: secret
      ),
      debugShowCheckedModeBanner: false
    );
  }
}
