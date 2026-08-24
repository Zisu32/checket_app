import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/widgets/app_navbar.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'tabs/tenant_tab_view.dart';
import 'tabs/user_tab_view.dart';
import 'package:web/web.dart' as web;

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    web.document.title = 'Checket Admin';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTopBar(
        syncService: SyncService(),
        pulseAnimation: _pulseAnimation,
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
          NavbarItem(icon: Icons.warehouse_rounded, label: 'Tenants'),
          NavbarItem(icon: Icons.people_alt_rounded, label: 'Users'),
        ],
      ),
    );
  }
}
