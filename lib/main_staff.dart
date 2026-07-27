import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_app/views/dashboard_view.dart';
import 'staff_app/views/qr_display_view.dart';
import 'shared/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activate Hash-Routing for GitHub Pages stability
  usePathUrlStrategy();

  // Initialize Supabase with environment variables (injected by GitHub Actions)
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://dtvozyjaljzptarkyzgo.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_pfzZGNSHyrnIZ-tfdrGvfw_50HpC1U2'),
  );

  // Initialize Sync Service (Drift & Supabase) with unique name
  await SyncService().init(dbName: 'checket_staff_db');

  runApp(const ChecketStaffApp());
}

class ChecketStaffApp extends StatelessWidget {
  const ChecketStaffApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checket Staff',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        // Handle /qr?id=5&secret=ABC format
        if (settings.name != null && settings.name!.startsWith('/qr')) {
          final uri = Uri.parse(settings.name!);
          final id = int.tryParse(uri.queryParameters['id'] ?? '');
          final secret = uri.queryParameters['secret'] ?? '';

          if (id != null) {
            return MaterialPageRoute(
              builder: (_) => QrDisplayView(ticketId: id, secret: secret),
            );
          }
        }
        
        // Default to Dashboard
        return MaterialPageRoute(builder: (_) => const StaffDashboard());
      },
    );
  }
}
