import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sync_service.dart';
import '../widgets/top_bar.dart';
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
      appBar: TopBar(
        syncService: _syncService,
        pulseAnimation: _pulseAnimation,
        showSettings: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.white, size: 24),
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TicketSettingsTabView(),
          WorkstationSettingsTabView(),
          ProfileSettingsTabView(),
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
            icon: Icon(Icons.confirmation_number),
            label: 'Ticket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tablet_android),
            label: 'Arbeitsplatz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
