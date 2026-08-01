import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_app/views/dashboard_view.dart';
import 'staff_app/views/qr_display_view.dart';
import 'shared/services/sync_service.dart';
import 'shared/theme/brand_colors.dart';
import 'package:web/web.dart' as web;

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
                const Text('Startfehler oder Absturz (Staff):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: BrandColors.white)),
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

    await Supabase.initialize(url: url, anonKey: anonKey);
    await SyncService().init(dbName: 'checket_staff_db');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checket Staff',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      // The builder wraps every route, showing a Splash screen while initializing
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
            // Once ready, show the actual navigation child (Dashboard)
            return child ?? const SizedBox.shrink();
          },
        );
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        
        if (name.contains('/qr')) {
          return MaterialPageRoute(
            builder: (_) => QrDisplayView(),
          );
        }
        
        return MaterialPageRoute(builder: (_) => const StaffDashboard());
      },
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
