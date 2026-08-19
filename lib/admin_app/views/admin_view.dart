import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/widgets/app_navbar.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'tabs/tenant_tab_view.dart';
import 'tabs/user_tab_view.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTopBar(
        syncService: SyncService(),
        pulseAnimation: const AlwaysStoppedAnimation(1.0),
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 24),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TenantTabView(),
          UserTabView(),
        ],
      ),
      bottomNavigationBar: AppNavbar(
        selectedIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
        items: [
          NavbarItem(icon: Icons.warehouse_rounded, label: 'Tenant'),
          NavbarItem(icon: Icons.people_alt_rounded, label: 'User'),
        ],
      ),
    );
  }
}
