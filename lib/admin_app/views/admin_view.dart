import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sync_service.dart';
import '../../staff_app/widgets/top_bar.dart';
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
      appBar: TopBar(
        syncService: SyncService(),
        pulseAnimation: const AlwaysStoppedAnimation(1.0),
        showSettings: false,
        leading: const SizedBox.shrink(),
        trailing: IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.white, size: 24),
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TenantTabView(),
          UserTabView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.header,
        selectedItemColor: AppTheme.active,
        unselectedItemColor: AppTheme.free,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_rounded),
            label: 'Tenant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'User',
          ),
        ],
      ),
    );
  }
}
