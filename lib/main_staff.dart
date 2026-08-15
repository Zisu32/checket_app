import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_app/views/staff_view.dart';
import 'staff_app/views/qr_display_view.dart';
import 'staff_app/views/settings_view.dart';
import 'shared/services/sync_service.dart';
import 'shared/services/route_service.dart';
import 'widgets/splash.dart';
import 'widgets/error.dart';
import 'widgets/fatal_error.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Catcher for Debugging
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FatalError(details: details, titleSuffix: 'Staff');
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
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    if (url.isEmpty || publishableKey.isEmpty) {
      throw Exception('Konfiguration fehlt (URL/KEY). Bitte GitHub Secrets prüfen.');
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
    await SyncService().init(dbName: 'checket_staff_db');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checket Staff',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Splash();
            }
            if (snapshot.hasError) {
              return Error(
                error: snapshot.error.toString(),
                onRetry: () => setState(() { _initFuture = _initialize(); }),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
      onGenerateRoute: (settings) {
        final params = RouteService().parseStaffParams(settings.name);

        if (params.isQrRoute) {
          return MaterialPageRoute(
            builder: (_) => QrDisplayView(
              ticketId: params.id, 
              secret: params.secret
            ),
          );
        }

        if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (_) => const SettingsView());
        }
        
        return MaterialPageRoute(builder: (_) => const StaffView());
      },
    );
  }
}
