import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app/views/customer_view.dart';
import 'customer_app/widgets/no_ticket.dart';
import 'shared/services/sync_service.dart';
import 'shared/services/route_service.dart';
import 'widgets/splash.dart';
import 'widgets/error.dart';
import 'widgets/fatal_error.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Catcher for Debugging
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FatalError(details: details, titleSuffix: 'Costumer');
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
      home: const _CustomerRouteHandler(),
    );
  }
}

class _CustomerRouteHandler extends StatelessWidget {
  const _CustomerRouteHandler();

  @override
  Widget build(BuildContext context) {
    final params = RouteService().parseCustomerParams();

    if (params.id == null || params.secret == null) {
      return const NoTicket();
    }
    
    return CustomerView(
      ticketId: params.id, 
      secret: params.secret
    );
  }
}
