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
                const Text('Startfehler oder Absturz (Staff):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 12),<!DOCTYPE html>
          <html>
          <head>
          <!--
          If you are serving your web app in a path other than the root, change the
          href value below to reflect the base path you are serving from.

          The path provided below has to start and end with a slash "/" in order for
          it to work correctly.

          For more details:
          * https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base

          This is a placeholder for base href that will be replaced by the value of
          the `--base-href` argument provided to `flutter build`.
          -->
          <base href="$FLUTTER_BASE_HREF">

          <meta charset="UTF-8">
          <meta content="IE=Edge" http-equiv="X-UA-Compatible">
          <meta name="description" content="A new Flutter project.">

          <!-- iOS meta tags & icons -->
          <meta name="mobile-web-app-capable" content="yes">
          <meta name="apple-mobile-web-app-status-bar-style" content="black">
          <meta name="apple-mobile-web-app-title" content="checket">
          <link rel="apple-touch-icon" href="icons/Icon-192.png">

          <!-- Favicon -->
          <link rel="icon" type="image/png" href="favicon.png"/>

          <title>checket</title>
          <link rel="manifest" href="manifest.json">
          <script>
          // Debugging Trick: Show errors as a red bar on iPhone
          window.onerror = function(message, source, lineno) {
        const div = document.createElement('div');
        div.style = 'position:fixed;top:0;left:0;background:red;color:white;z-index:9999;padding:20px;width:100%;font-size:14px;';
        div.innerText = 'Fehler: ' + message + '\nDatei: ' + source + '\nZeile: ' + lineno;
        document.body.appendChild(div);
        return false;
        };
        </script>
        </head>
        <body>
        <!--
        You can customize the "flutter_bootstrap.js" script.
        This is useful to provide a custom configuration to the Flutter loader
        or to give the user feedback during the initialization process.

        For more details:
        * https://docs.flutter.dev/platform-integration/web/initialization
        -->
        <script src="flutter_bootstrap.js" async></script>
        </body>
        </html>

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
        
        // Standard route parsing from the browser's URL hash
        if (name.contains('/qr')) {
          final uri = Uri.parse(name.startsWith('/') ? name : '/$name');
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
