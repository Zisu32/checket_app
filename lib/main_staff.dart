import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_app/views/dashboard_view.dart';
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

  // Initialize Sync Service (Drift & Supabase)
  await SyncService().init();

  runApp(const ChecketStaffApp());
}

class ChecketStaffApp extends StatelessWidget {
  const ChecketStaffApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Checket Staff',
        theme: ThemeData.dark(),
        home: const StaffDashboard(),
        debugShowCheckedModeBanner: false
    );
  }
}
