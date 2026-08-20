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
    final bool isAdminRoute = initialRoute.startsWith('/admin');
    final bool isStaffRoute = initialRoute.startsWith('/staff');

    return MaterialApp(
      title: isAdminRoute ? 'Checket Admin' : 'Checket Staff',
      theme: ThemeData.dark().copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppTheme.white,
          selectionColor: AppTheme.white.withValues(alpha: 0.24),
          selectionHandleColor: AppTheme.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        final bool isCurrentlyAdmin = name.startsWith('/admin');
        final bool isCurrentlyStaff = name.startsWith('/staff');
        
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final session = Supabase.instance.client.auth.currentSession;
              
              if (session == null) {
                return LoginView(isAdminMode: isCurrentlyAdmin);
              }

              return _AuthenticatedApp(
                isAdminMode: isCurrentlyAdmin,
                isStaffMode: isCurrentlyStaff,
                initialRoute: name,
              );
            },
          ),
        );
      },
    );
  }
}

class _AuthenticatedApp extends StatefulWidget {
  final bool isAdminMode;
  final bool isStaffMode;
  final String initialRoute;
  const _AuthenticatedApp({
    required this.isAdminMode, 
    required this.isStaffMode,
    required this.initialRoute
  });

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

            if (widget.isAdminMode) {
              return const AdminView();
            }

            return Navigator(
              initialRoute: widget.initialRoute,
              onGenerateRoute: (settings) {
                final params = RouteService().parseStaffParams(settings.name);
                if (params.isQrRoute) {
                  return MaterialPageRoute(
                    builder: (_) => QrDisplayView(ticketId: params.id, secret: params.secret),
                  );
                }
                
                if (settings.name == '/staff/settings') {
                  return MaterialPageRoute(builder: (_) => const SettingsView());
                }
                
                return MaterialPageRoute(builder: (_) => const StaffView());
              },
            );
          },
        );
      },
    );
  }
}
