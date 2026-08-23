import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app/views/customer_view.dart';
import 'customer_app/widgets/no_ticket.dart';
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
    return FatalError(details: details, titleSuffix: 'Customer');
  };

  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (url.isEmpty || publishableKey.isEmpty) {
    runApp(MaterialApp(home: Error(error: 'Konfiguration fehlt.', onRetry: () {})));
    return;
  }

  await Supabase.initialize(url: url, publishableKey: publishableKey);
  
  runApp(const ChecketCustomerWebApp());
}

class ChecketCustomerWebApp extends StatelessWidget {
  const ChecketCustomerWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checket Ticket',
      theme: ThemeData.dark().copyWith(
        inputDecorationTheme: AppTheme.inputDecorationTheme,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppTheme.white,
          selectionColor: AppTheme.white.withValues(alpha: 0.24),
          selectionHandleColor: AppTheme.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const _Router(),
    );
  }
}

class _Router extends StatelessWidget {
  const _Router();

  @override
  Widget build(BuildContext context) {
    final params = RouteService().parseCustomerParams();
    return _AuthenticatedApp(
      ticketId: params.id,
      secret: params.secret,
      tenant: params.tenant,
    );
  }
}

class _AuthenticatedApp extends StatefulWidget {
  final int? ticketId;
  final String? secret;
  final String? tenant;

  const _AuthenticatedApp({this.ticketId, this.secret, this.tenant});

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
    // Guest app needs to know which schema to sync with
    await SyncService().init(
      dbName: 'checket_customer_${widget.tenant ?? "public"}',
      schema: widget.tenant,
    );
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

        if (widget.ticketId == null || widget.secret == null) {
          return const NoTicket();
        }

        return CustomerView(
          ticketId: widget.ticketId,
          secret: widget.secret,
        );
      },
    );
  }
}
