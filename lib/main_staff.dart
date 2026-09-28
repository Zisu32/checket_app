import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'admin_app/views/admin_view.dart';
import 'staff_app/views/staff_view.dart';
import 'staff_app/views/qr_display_view.dart';
import 'staff_app/views/settings_view.dart';
import 'shared/views/login_view.dart';
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

  String _getInitialRoute() {
    String hash = web.window.location.hash;
    if (hash.startsWith('#')) {
      hash = hash.substring(1);
    }
    return hash.isEmpty ? '/' : hash;
  }

  @override
  Widget build(BuildContext context) {
    final String initialRoute = _getInitialRoute();

    return MaterialApp(
      title: 'Checket',
      theme: ThemeData.dark().copyWith(
        inputDecorationTheme: AppTheme.inputDecorationTheme,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppTheme.white,
          selectionColor: AppTheme.white.withValues(alpha: 0.24),
          selectionHandleColor: AppTheme.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      builder: (context, child) {
        return StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = Supabase.instance.client.auth.currentSession;
            if (session == null) {
              final isCurrentlyAdmin = web.window.location.hash.startsWith('#/admin');
              return LoginView(isAdminMode: isCurrentlyAdmin);
            }
            return _Initializer(child: child!);
          },
        );
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        
        if (name.startsWith('/qr')) {
          final params = RouteService().parseStaffParams(name);
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => QrDisplayView(ticketId: params.id, secret: params.secret),
          );
        }

        if (name == '/admin') {
          return MaterialPageRoute(settings: settings, builder: (_) => const AdminView());
        }

        if (name == '/settings' || name == '/staff/settings') {
          return MaterialPageRoute(settings: settings, builder: (_) => const SettingsView());
        }

        // Default is StaffView (Dashboard)
        return MaterialPageRoute(settings: settings, builder: (_) => const StaffView());
      },
    );
  }
}

class _Initializer extends StatefulWidget {
  final Widget child;
  const _Initializer({required this.child});

  @override
  State<_Initializer> createState() => _InitializerState();
}

class _InitializerState extends State<_Initializer> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    if (SyncService().isInitialized.value) return;
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
        
        return ValueListenableBuilder<String?>(
          valueListenable: SyncService().errorNotifier,
          builder: (context, error, _) {
            if (error != null) {
              return Scaffold(
                body: Error(
                  error: error,
                  onRetry: () => setState(() { _initFuture = _initialize(); }),
                ),
              );
            }
            return widget.child;
          },
        );
      },
    );
  }
}
