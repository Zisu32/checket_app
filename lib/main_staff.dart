import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_app/views/dashboard_view.dart';
import 'staff_app/views/qr_display_view.dart';
import 'shared/services/sync_service.dart';
import 'package:web/web.dart' as web;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Initialize Sync Service (Drift & Supabase) with unique name
  await SyncService().init(dbName: 'checket_staff_db');

  runApp(const ChecketStaffApp());
}

class ChecketStaffApp extends StatelessWidget {
  const ChecketStaffApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Robust direct routing for Flutter Web
    final href = web.window.location.href;
    final fragment = web.window.location.hash;

    if (fragment.contains('/qr')) {
      final uri = Uri.parse(fragment.startsWith('#') ? fragment.substring(1) : fragment);
      final id = int.tryParse(uri.queryParameters['id'] ?? '');
      final secret = uri.queryParameters['secret'] ?? '';

      if (id != null) {
        return MaterialApp(
          title: 'Checket Monitor',
          theme: ThemeData.dark(),
          debugShowCheckedModeBanner: false,
          home: QrDisplayView(ticketId: id, secret: secret),
        );
      }
    }

    // Default to Dashboard
    return MaterialApp(
      title: 'Checket Staff',
      theme: ThemeData.dark(),
      home: const StaffDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
