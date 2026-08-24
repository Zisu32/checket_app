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

class _SettingsViewState extends State<SettingsView> {
  int _currentIndex = 1; // Default: Arbeitsplatz

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTopBar(
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
