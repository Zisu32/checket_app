import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'staff_app/views/staff_view.dart';
import 'staff_app/views/qr_display_view.dart';
import 'staff_app/views/settings_view.dart';
import 'staff_app/views/login_view.dart';
import 'staff_app/views/admin_view.dart';
import 'shared/services/sync_service.dart';
import 'shared/services/route_service.dart';
import 'shared/theme/app_theme.dart';
import 'widgets/splash.dart';
import 'widgets/error.dart';
import 'widgets/fatal_error.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Catcher for Debugging
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FatalError(details: details, titleSuffix: 'Staff');
  };

  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (url.isEmpty || publishableKey.isEmpty) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Error(error: 'Konfiguration fehlt (URL/KEY).', onRetry: () {}),
    ));
    return;
  }

  await Supabase.initialize(url: url, publishableKey: publishableKey);
  
  runApp(const ChecketStaffApp());
}

class ChecketStaffApp extends StatelessWidget {
  const ChecketStaffApp({super.key});

  bool _isAdminPath() {
    final path = web.window.location.pathname;
    return path.endsWith('/admin') || path.endsWith('/admin/');
  }

  @override
  Widget build(BuildContext context) {
    final isAdminMode = _isAdminPath();

    return MaterialApp(
      title: isAdminMode ? 'Checket Admin' : 'Checket Staff',
      theme: ThemeData.dark().copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.white24,
          selectionHandleColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          
          if (session == null) {
            return LoginView(isAdminMode: isAdminMode);
          }

          return _AuthenticatedApp(isAdminMode: isAdminMode);
        },
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (_) => const SettingsView());
        }
        return null;
      },
    );
  }
}

class _AuthenticatedApp extends StatefulWidget {
  final bool isAdminMode;
  const _AuthenticatedApp({required this.isAdminMode});

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    final dbName = 'checket_staff_${user?.id ?? "unknown"}';
    await SyncService().init(dbName: dbName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Splash();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Error(
              error: snapshot.error.toString(),
              onRetry: () => setState(() { _initFuture = _initialize(); }),
            ),
          );
        }

        if (widget.isAdminMode) {
          return const AdminView();
        }

        return Navigator(
          onGenerateRoute: (settings) {
             final params = RouteService().parseStaffParams(settings.name);
             if (params.isQrRoute) {
               return MaterialPageRoute(
                 builder: (_) => QrDisplayView(ticketId: params.id, secret: params.secret),
               );
             }
             return MaterialPageRoute(builder: (_) => const StaffView());
          },
        );
      },
    );
  }
}
