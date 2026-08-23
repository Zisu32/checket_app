import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/monitor_service.dart';
import 'tabs/lost_found_tab_view.dart';
import 'tabs/session_end_tab_view.dart';
import 'tabs/dashboard_tab_view.dart';
import '../widgets/loading_screen.dart';
import '../widgets/page_indicator.dart';
import '../widgets/wardrobe_action_sheet.dart';
import '../../shared/widgets/app_navbar.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_primary_button.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key});
  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> with SingleTickerProviderStateMixin {
  final _syncService = SyncService();
  bool _showTimeoutMessage = false;
  Timer? _timeoutTimer;
  
  // Navigation & Pagination
  int _selectedNavIndex = 1; // Default: Dashboard
  late PageController _pageController;
  int _currentPage = 0;
  final int _itemsPerPage = 100;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    web.document.title = 'Checket Staff';
    
    _pageController = PageController(initialPage: 0);
    
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showTimeoutMessage = true);
      }
    });

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
    _timeoutTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _generateSecret() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _syncMonitor(int id, String secret) {
    MonitorService().updateMonitor(id, secret);
    final origin = web.window.location.origin;
    final path = web.window.location.pathname;
    // Use a clean URL without sensitive parameters
    final qrUrl = '$origin$path#/qr';
    web.window.open(qrUrl, 'checket_monitor');
  }

  void _showSettingsAuth() {
    final passwordController = TextEditingController();
    bool isAuthenticating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: 'Zugriff geschützt',
          subtitle: 'Anmeldung erforderlich',
          body: StatefulBuilder(
            builder: (context, setFieldState) => TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: AppTheme.white),
              cursorColor: AppTheme.white,
              onChanged: (_) => setFieldState(() {}),
              decoration: InputDecoration(
                labelText: 'Passwort eingeben',
                errorText: (passwordController.text.isEmpty && isAuthenticating) ? '' : null,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: AppTheme.free)),
            ),
            isAuthenticating
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.active),
                    ),
                  )
                : AppPrimaryButton(
                    text: 'Bestätigen',
                    color: AppTheme.active,
                    onTap: () async {
                      setDialogState(() => isAuthenticating = true);
                      final success = await _syncService.reauthenticate(passwordController.text);
                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings');
                        }
                      } else {
                        setDialogState(() => isAuthenticating = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Passwort falsch'));
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showLockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Schichtende nicht möglich!',
        subtitle: 'Es sind noch unbezahlte Jacken im System. Diese müssen zuerst bezahlt werden, bevor die Schicht beendet werden kann.',
        actions: [
          AppPrimaryButton(
            text: 'Okay',
            color: AppTheme.active,
            onTap: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WardrobeSlot>>(
      stream: _syncService.watchSlots(),
      builder: (context, snapshot) {
        final allSlots = snapshot.data ?? [];
        
        return ValueListenableBuilder<String?>(
          valueListenable: _syncService.errorNotifier,
          builder: (context, error, _) {
            if (allSlots.isEmpty || error != null) {
              return LoadingScreen(
                showTimeoutMessage: _showTimeoutMessage,
                onManualReload: () => _syncService.pullFromSupabase(),
                error: error,
              );
            }

            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppTopBar(
                syncService: _syncService,
                pulseAnimation: _pulseAnimation,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 26),
                    onPressed: _showSettingsAuth,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: _buildBody(allSlots),
                  ),
                  if (_selectedNavIndex == 1)
                    PageIndicator(
                      totalSlots: allSlots.length,
                      itemsPerPage: _itemsPerPage,
                      currentPage: _currentPage,
                      onPageSelected: (page) {
                        _pageController.animateToPage(
                          page,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                ],
              ),
              bottomNavigationBar: AppNavbar(
                selectedIndex: _selectedNavIndex,
                onTabSelected: (index) => setState(() => _selectedNavIndex = index),
                items: [
                  NavbarItem(icon: Icons.inventory_2_outlined, label: 'Fundbüro'),
                  NavbarItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
                  NavbarItem(
                    icon: Icons.swap_horiz_rounded, 
                    label: 'Schichtende',
                    onBeforeTap: () async {
                      final unpaidCount = allSlots.where((s) => s.status == 'unpaid').length;
                      if (unpaidCount > 0) {
                        _showLockDialog();
                        return false;
                      }
                      return true;
                    }
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildBody(List<WardrobeSlot> allSlots) {
    switch (_selectedNavIndex) {
      case 0:
        return LostFoundTabView(
          syncService: _syncService,
          onSyncMonitor: _syncMonitor,
        );
      case 1:
        return DashboardTabView(
          slots: allSlots,
          pageController: _pageController,
          itemsPerPage: _itemsPerPage,
          onTap: (slot) => _zeigeAktionen(context, slot),
          onPageChanged: (index) => setState(() => _currentPage = index),
        );
      case 2:
        return SessionEndTabView(
          allSlots: allSlots,
          syncService: _syncService,
          onComplete: () => setState(() => _selectedNavIndex = 1),
        );
      default:
        return const Center(child: Text('Seite nicht gefunden', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)));
    }
  }

  void _zeigeAktionen(BuildContext context, WardrobeSlot initialSlot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      builder: (modalContext) {
        return WardrobeActionSheet(
          initialSlot: initialSlot,
          syncService: _syncService,
          onSyncMonitor: _syncMonitor,
          onGenerateSecret: _generateSecret,
        );
      },
    );
  }
}
