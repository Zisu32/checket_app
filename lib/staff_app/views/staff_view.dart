import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/brand_colors.dart';
import '../../shared/services/monitor_service.dart';
import 'tabs/lost_found_tab_view.dart';
import 'tabs/session_end_tab_view.dart';
import 'tabs/dashboard_tab_view.dart';
import '../widgets/staff_navbar.dart';

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
    final qrUrl = '$origin$path#/qr';
    web.window.open(qrUrl, 'checket_monitor');
  }

  void _zeigeSperrDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BrandColors.background,
        title: Row(
          children: [
            const Icon(Icons.loop, color: BrandColors.white, size: 24),
            const SizedBox(width: 12),
            const Text('Schichtende\nnicht möglich', style: TextStyle(color: BrandColors.white)),
          ],
        ),
        content: const Text(
          'Es sind noch nicht bezahlte Jacken im System. Diese müssen zuerst bezahlt werden, bevor die Schicht beendet werden kann.',
          style: TextStyle(color: BrandColors.white)
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.active,
              foregroundColor: BrandColors.white,
            ),
            child: const Text('Okay', style: TextStyle(fontWeight: FontWeight.bold))
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
          return _buildLoadingScreen();
        }

        return Scaffold(
          backgroundColor: BrandColors.background,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(
                child: _buildBody(allSlots),
              ),
              if (_selectedNavIndex == 1) _buildPageIndicator(allSlots),
            ],
          ),
          bottomNavigationBar: StaffNavbar(
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
        return const Center(child: Text('Seite nicht gefunden', style: TextStyle(color: BrandColors.white)));
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: AppBar(
        backgroundColor: BrandColors.header,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/full-icon.png', 
              height: 28,
              errorBuilder: (_, __, ___) => const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: BrandColors.white, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<SyncStatus>(
              valueListenable: _syncService.statusNotifier,
              builder: (context, status, _) {
                Color statusColor = BrandColors.active;
                if (status == SyncStatus.syncing) statusColor = BrandColors.temporary;
                if (status == SyncStatus.offline) statusColor = BrandColors.unpaid;

                return AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: _pulseAnimation.value),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: _pulseAnimation.value * 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: BrandColors.active),
            if (_showTimeoutMessage) ...[
              const SizedBox(height: 24),
              const Text('Synchronisierung läuft...', textAlign: TextAlign.center, style: TextStyle(color: BrandColors.white)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _syncService.pullFromSupabase(),
                child: const Text('Manueller Reload', style: TextStyle(color: BrandColors.active)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(List<WardrobeSlot> allSlots) {
    final totalPages = (allSlots.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index ? BrandColors.white : BrandColors.free,
            ),
          );
        }),
      ),
    );
  }

  void _zeigeAktionen(BuildContext context, WardrobeSlot initialSlot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrandColors.background,
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return StreamBuilder<List<WardrobeSlot>>(
              stream: _syncService.watchSlots(),
              builder: (context, snapshot) {
                final slots = snapshot.data ?? [];
                final slot = slots.firstWhere((s) => s.id == initialSlot.id, orElse: () => initialSlot);

                return Container(
                  padding: EdgeInsets.only(
                    left: 24, right: 24, top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Bügel ${slot.id}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BrandColors.white)),
                      const SizedBox(height: 16),
                      
                      if (slot.status == 'active' || slot.status == 'temporary' || slot.status == 'forgotten') ...[
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _syncMonitor(-1, 'recovery');
                              Navigator.pop(modalContext);
                            },
                            icon: const Icon(Icons.qr_code_2, size: 20),
                            label: const Text('Ticket wiederherstellen', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandColors.active,
                              foregroundColor: BrandColors.white,
                              minimumSize: const Size(280, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 6),
                      const Divider(height: 24, indent: 20, endIndent: 20, color: BrandColors.surface),
                      const SizedBox(height: 8),
                      
                      if (slot.status == 'free') 
                        ListTile(
                          leading: const Icon(Icons.add_box, color: BrandColors.active), 
                          title: const Text('Jacke einchecken', style: TextStyle(color: BrandColors.white)),
                          onTap: () async { 
                            final secret = _generateSecret();
                            final updated = slot.copyWith(
                              status: 'unpaid', 
                              secret: secret,
                              isPaid: false,
                              paymentMethod: 'none',
                              updatedAt: DateTime.now()
                            );
                            
                            _syncMonitor(slot.id, secret);
                            await _syncService.updateSlot(updated);
                          }
                        ),
                        
                      if (slot.status == 'unpaid') ...[
                        ListTile(
                          leading: const Icon(Icons.contactless_outlined, color: BrandColors.active), 
                          title: const Text('Kontaktloses bezahlen', style: TextStyle(color: BrandColors.white)),
                          onTap: () async { 
                            final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'nfc', updatedAt: DateTime.now());
                            await _syncService.updateSlot(updated);
                            if (mounted) Navigator.pop(modalContext); 
                          }
                        ),
                        ListTile(
                          leading: const Icon(Icons.euro, color: BrandColors.secret),
                          title: const Text('Bar bezahlen', style: TextStyle(color: BrandColors.white)),
                          onTap: () async { 
                            final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'bar', updatedAt: DateTime.now());
                            await _syncService.updateSlot(updated);
                            if (mounted) Navigator.pop(modalContext); 
                          }
                        ),
                      ],
                      
                      if (slot.status == 'active' || slot.status == 'temporary') ...[
                        if (slot.status == 'active')
                          ListTile(
                            leading: const Icon(Icons.pause, color: BrandColors.temporary),
                            title: const Text('Temporärer Ausgang', style: TextStyle(color: BrandColors.white)),
                            onTap: () async { 
                              final updated = slot.copyWith(status: 'temporary', updatedAt: DateTime.now());
                              await _syncService.updateSlot(updated);
                              if (mounted) Navigator.pop(modalContext); 
                            }
                          )
                        else
                          ListTile(
                            leading: const Icon(Icons.play_arrow, color: BrandColors.active), 
                            title: const Text('Wieder zurück', style: TextStyle(color: BrandColors.white)),
                            onTap: () async { 
                              final updated = slot.copyWith(status: 'active', updatedAt: DateTime.now());
                              await _syncService.updateSlot(updated);
                              if (mounted) Navigator.pop(modalContext); 
                            }
                          ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: BrandColors.free),
                          title: const Text('Endgültig auschecken', style: TextStyle(color: BrandColors.white)),
                          onTap: () async { 
                            final updated = slot.copyWith(
                              status: 'free', 
                              isPaid: false, 
                              secret: '',
                              paymentMethod: 'none',
                              updatedAt: DateTime.now()
                            );
                            await _syncService.updateSlot(updated);
                            if (mounted) Navigator.pop(modalContext); 
                          }
                        ),
                      ],
                    ],
                  ),
                );
              }
            );
          }
        );
      },
    );
  }
}
