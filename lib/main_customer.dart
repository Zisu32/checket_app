import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app/views/customer_view.dart';
import 'shared/services/sync_service.dart';
import 'shared/services/route_service.dart';
import 'shared/theme/brand_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Catcher for Debugging
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
                const Text('Startfehler oder Absturz:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: BrandColors.white)),
                const SizedBox(height: 12),
                Text(
                  '${details.exception}\n\n${details.stack}',
                  style: const TextStyle(color: BrandColors.unpaid, fontSize: 12),
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
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    if (url.isEmpty || publishableKey.isEmpty) {
      throw Exception('Konfiguration fehlt (URL/KEY). Bitte GitHub Secrets prüfen.');
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
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
            return child ?? const SizedBox.shrink();
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
            Image.asset('assets/images/full-icon.png', height: 60, errorBuilder: (_, __, ___) =>
            const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: BrandColors.white))),
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
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: BrandColors.free, fontSize: 13)),
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
    final params = RouteService().parseCustomerParams();

    if (params.id == null || params.secret == null) {
      return Scaffold(
        backgroundColor: BrandColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/full-icon.png', height: 60, errorBuilder: (_, __, ___) =>
                  const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: BrandColors.white))),
                const SizedBox(height: 40),
                const Icon(Icons.search_off, color: BrandColors.free, size: 64),
                const SizedBox(height: 24),
                const Text('Kein aktives Ticket gefunden', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BrandColors.white)),
                const SizedBox(height: 12),
                const Text('Bitte scanne den QR-Code oder wende dich an das Personal.', textAlign: TextAlign.center, style: TextStyle(color: BrandColors.free, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }
    
    return CustomerView(
      ticketId: params.id, 
      secret: params.secret
    );
  }
}
