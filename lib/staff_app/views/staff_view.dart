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
import '../widgets/navbar.dart';
import '../widgets/top_bar.dart';
import '../widgets/loading_screen.dart';
import '../widgets/page_indicator.dart';
import '../widgets/wardrobe_action_sheet.dart';

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

  void _zeigeSperrDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Row(
          children: [
            const Icon(Icons.loop, color: AppTheme.white, size: AppTheme.medium),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Schichtende nicht möglich',
                  style: TextStyle(color: AppTheme.white, fontSize: AppTheme.medium),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Es sind noch nicht bezahlte Jacken im System. Diese müssen zuerst bezahlt werden, bevor die Schicht beendet werden kann.',
          style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          AppTheme.buildPrimaryButton(
            text: 'Okay',
            color: AppTheme.active,
            onTap: () => Navigator.pop(dialogContext),
            width: 100,
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
        
        if (allSlots.isEmpty) {
          return LoadingScreen(
            showTimeoutMessage: _showTimeoutMessage,
            onManualReload: () => _syncService.pullFromSupabase(),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: TopBar(
            syncService: _syncService,
            pulseAnimation: _pulseAnimation,
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
          bottomNavigationBar: Navbar(
            selectedIndex: _selectedNavIndex,
            allSlots: allSlots,
            onTabSelected: (index) => setState(() => _selectedNavIndex = index),
            onLockedTabClick: _zeigeSperrDialog,
          ),
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
