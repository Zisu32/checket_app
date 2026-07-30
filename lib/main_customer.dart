import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app/views/webticket_view.dart';
import 'shared/services/sync_service.dart';
import 'shared/theme/brand_colors.dart';
import 'package:web/web.dart' as web;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Catcher for Grey Screen Debugging
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: BrandColors.unpaid, size: 48),
                const SizedBox(height: 20),
                const Text('Startfehler oder Absturz:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                  '${details.exception}\n\n${details.stack}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const ChecketCustomerWebApp());
}

class ChecketCustomerWebApp extends StatefulWidget {
  const ChecketCustomerWebApp({super.key});

  @override
  State<ChecketCustomerWebApp> createState() => _ChecketCustomerWebAppState();
}

class _ChecketCustomerWebAppState extends State<ChecketCustomerWebApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception('Konfiguration fehlt (URL/KEY). Bitte GitHub Secrets prüfen.');
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    await SyncService().init(dbName: 'checket_customer_db');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checket Ticket',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _buildSplash();
            }
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }
            return child!;
          },
        );
      },
      home: const _CustomerRouteHandler(),
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/full-icon.png', height: 60, errorBuilder: (_, __, ___) => const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white))),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: BrandColors.active),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: BrandColors.unpaid, size: 64),
              const SizedBox(height: 24),
              const Text('Initialisierungsfehler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() { _initFuture = _initialize(); }),
                child: const Text('Erneut versuchen'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerRouteHandler extends StatelessWidget {
  const _CustomerRouteHandler();

  @override
  Widget build(BuildContext context) {
    final fullUrl = web.window.location.href;
    final uri = Uri.parse(fullUrl);
    
    Map<String, String> params = Map.from(uri.queryParameters);
    if (uri.hasFragment) {
      final fragment = uri.fragment.contains('?') ? uri.fragment.split('?').last : '';
      if (fragment.isNotEmpty) {
        params.addAll(Uri.splitQueryString(fragment));
      }
    }

    String ticketIdStr = params['id'] ?? '';
    String secret = params['secret'] ?? '';

    // Fallback to localStorage
    if (ticketIdStr.isEmpty || secret.isEmpty) {
      ticketIdStr = web.window.localStorage.getItem('last_ticket_id') ?? '';
      secret = web.window.localStorage.getItem('last_ticket_secret') ?? '';
    } else {
      web.window.localStorage.setItem('last_ticket_id', ticketIdStr);
      web.window.localStorage.setItem('last_ticket_secret', secret);
    }

    final ticketId = int.tryParse(ticketIdStr);

    if (ticketId == null) {
      return const Scaffold(body: Center(child: Text('Kein aktives Ticket gefunden.')));
    }
    
    return CustomerWebTicketView(
      ticketId: ticketId, 
      secret: secret
    );
  }
}
