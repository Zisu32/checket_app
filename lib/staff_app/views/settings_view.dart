import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/widgets/app_navbar.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'tabs/ticket_settings_tab_view.dart';
import 'tabs/workstation_settings_tab_view.dart';
import 'tabs/profile_settings_tab_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  final _syncService = SyncService();
  int _currentIndex = 1; // Default: Arbeitsplatz

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
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
        syncService: _syncService,
        pulseAnimation: _pulseAnimation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 24),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TicketSettingsTabView(),
          WorkstationSettingsTabView(),
          ProfileSettingsTabView(),
        ],
      ),
      bottomNavigationBar: AppNavbar(
        selectedIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
        items: [
          NavbarItem(icon: Icons.confirmation_number, label: 'Ticket'),
          NavbarItem(icon: Icons.tablet_android, label: 'Arbeitsplatz'),
          NavbarItem(icon: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }
}
