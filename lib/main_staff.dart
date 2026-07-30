import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_app/views/dashboard_view.dart';
import 'staff_app/views/qr_display_view.dart';
import 'shared/services/sync_service.dart';
import 'shared/theme/brand_colors.dart';
import 'package:web/web.dart' as web;

void main() {
  // 1. Decouple initialization to prevent iOS gray screen hangs.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Visual Debugger: Replace gray screen with real error text
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
                const Text('Startfehler oder Absturz (Staff):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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

  runApp(const ChecketStaffApp());
}

class ChecketStaffApp extends StatefulWidget {
  const ChecketStaffApp({super.key});

  @override
  State<ChecketStaffApp> createState() => _ChecketStaffAppState();
}

class _ChecketStaffAppState extends State<ChecketStaffApp> {
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

    // Initialize Supabase
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    // Initialize Sync Service (Drift & Supabase)
    await SyncService().init(dbName: 'checket_staff_db');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checket Staff',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildSplash();
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          return const _StaffRootHandler();
        },
      ),
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
              const Text('Startfehler (Staff)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

class _StaffRootHandler extends StatelessWidget {
  const _StaffRootHandler();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        // Robust direct routing for Flutter Web
        final fragment = web.window.location.hash;

        if (fragment.contains('/qr')) {
          final uri = Uri.parse(fragment.startsWith('#') ? fragment.substring(1) : fragment);
          final id = int.tryParse(uri.queryParameters['id'] ?? '');
          final secret = uri.queryParameters['secret'] ?? '';

          if (id != null) {
            return MaterialPageRoute(
              builder: (_) => QrDisplayView(ticketId: id, secret: secret),
            );
          }
        }
        
        return MaterialPageRoute(builder: (_) => const StaffDashboard());
      },
    );
  }
}
