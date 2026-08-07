import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/brand_colors.dart';
import '../../shared/services/monitor_service.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with SingleTickerProviderStateMixin {
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

  void _schichtBeendenDialog(List<WardrobeSlot> allSlots) {
    final unpaidCount = allSlots.where((s) => s.status == 'unpaid').length;
    
    if (unpaidCount > 0) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: BrandColors.background,
          title: Row(
            children: [
              const Icon(Icons.refresh, color: BrandColors.unpaid, size: 24),
              const SizedBox(width: 12),
              const Text('Schichtende nicht möglich', style: TextStyle(color: BrandColors.white)),
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
      return;
    }

    final archiveCount = allSlots.where((s) => s.status == 'active').length;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BrandColors.background,
        title: Row(
          children: [
            const Icon(Icons.refresh, color: BrandColors.unpaid, size: 24),
            const SizedBox(width: 12),
            const Text('Schichtende', style: TextStyle(color: BrandColors.white)),
          ],
        ),
        content: Text('Sollen $archiveCount Jacken ins FUNDBÜRO verschoben und die Garderrobe geschlossen werden?', style: const TextStyle(color: BrandColors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Abbrechen', style: TextStyle(color: BrandColors.free))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.unpaid, foregroundColor: BrandColors.white),
            onPressed: () async {
              await _syncService.archiveAndResetShift();
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Ja, Schicht beenden', style: TextStyle(fontWeight: FontWeight.bold)),
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
                child: _selectedNavIndex == 0 
                  ? _buildFundbueroView() 
                  : _buildDashboardView(allSlots),
              ),
              if (_selectedNavIndex == 1) _buildPageIndicator(allSlots),
            ],
          ),
          bottomNavigationBar: _buildBottomNavbar(allSlots),
        );
      }
    );
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

  Widget _buildFundbueroView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: BrandColors.forgotten, size: 24),
                  const SizedBox(width: 12),
                  const Text('Fundbüro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BrandColors.white)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _syncMonitor(-1, 'recovery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.active,
                  foregroundColor: BrandColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: const Text('Ticket wiederherstellen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: BrandColors.surface),
        Expanded(
          child: StreamBuilder<List<LostItem>>(
            stream: _syncService.watchLostItems(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Center(child: Text('Keine Gegenstände im Fundbüro.', style: TextStyle(color: BrandColors.free)));
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final tag = item.createdAt.day.toString().padLeft(2, '0');
                  final monat = item.createdAt.month.toString().padLeft(2, '0');
                  final jahr = item.createdAt.year;

                  return Card(
                    color: BrandColors.surface,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: BrandColors.forgotten, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text('${item.originalSlotId}', style: const TextStyle(color: BrandColors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                      ),
                      title: const Text('Garderobenplatz', style: TextStyle(color: BrandColors.white)),
                      subtitle: Text('$tag.$monat.$jahr', style: const TextStyle(color: BrandColors.free, fontSize: 14)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: BrandColors.active, foregroundColor: BrandColors.white),
                        onPressed: () => _syncService.handOverLostItem(item),
                        child: const Text('Aushändigen', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardView(List<WardrobeSlot> allSlots) {
    final totalPages = (allSlots.length / _itemsPerPage).ceil();

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: totalPages,
      itemBuilder: (context, pageIndex) {
        final displaySlots = allSlots.skip(pageIndex * _itemsPerPage).take(_itemsPerPage).toList();
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 40, 
            mainAxisSpacing: 6, 
            crossAxisSpacing: 6,
            mainAxisExtent: 40,
          ),
          itemCount: displaySlots.length,
          itemBuilder: (context, index) {
            final slot = displaySlots[index];
            Color kachelFarbe = BrandColors.surface;
            if (slot.status == 'unpaid') kachelFarbe = BrandColors.unpaid;
            if (slot.status == 'active') kachelFarbe = BrandColors.active;
            if (slot.status == 'temporary') kachelFarbe = BrandColors.temporary;
            if (slot.status == 'forgotten') kachelFarbe = BrandColors.forgotten;

            return InkWell(
              onTap: () => _zeigeAktionen(context, slot),
              child: Container(
                decoration: BoxDecoration(color: kachelFarbe, borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text('${slot.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BrandColors.white))
                ),
              ),
            );
          },
        );
      },
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

  Widget _buildBottomNavbar(List<WardrobeSlot> allSlots) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: BrandColors.header,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavbarItem(0, Icons.inventory_2_outlined, 'Fundbüro'),
          _buildNavbarItem(1, Icons.grid_view_rounded, 'Dashboard'),
          _buildNavbarItem(2, Icons.loop, 'Schichtende', isAction: true, allSlots: allSlots),
        ],
      ),
    );
  }

  Widget _buildNavbarItem(int index, IconData icon, String label, {bool isAction = false, List<WardrobeSlot>? allSlots}) {
    final isActive = _selectedNavIndex == index;
    final color = isActive ? BrandColors.white : BrandColors.surface;

    return InkWell(
      onTap: () {
        if (isAction) {
          _schichtBeendenDialog(allSlots ?? []);
        } else {
          setState(() => _selectedNavIndex = index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          if (isActive && !isAction)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 24, height: 3,
              decoration: BoxDecoration(
                color: BrandColors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            )
        ],
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
                      const Divider(height: 24, color: BrandColors.free),
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
