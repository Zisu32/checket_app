import 'package:flutter/material.dart';
import 'staff_app/views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChecketStaffApp());
}

class ChecketStaffApp extends StatelessWidget {
  const ChecketStaffApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Checket',
        theme: ThemeData.dark(),
        home: const StaffDashboard(),
        debugShowCheckedModeBanner: false
    );
  }
}