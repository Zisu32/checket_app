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
  
  int _currentPage = 0;
  final int _itemsPerPage = 100;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    web.document.title = 'Checket Staff';
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
    // 1. Send instant message to existing tab via BroadcastChannel
    MonitorService().updateMonitor(id, secret);

    // 2. Standardize URL for monitor tab - robust Origin/Path/Hash combination
    final origin = web.window.location.origin;
    final path = web.window.location.pathname;
    final qrUrl = '$origin$path#/qr?id=$id&secret=$secret';
    
    // Named tab 'checket_monitor' ensures reuse and updates existing display
    web.window.open(qrUrl, 'checket_monitor');
  }

  void _schichtBeendenDialog(List<WardrobeSlot> allSlots) {
    final unpaidCount = allSlots.where((s) => s.status == 'unpaid').length;
    
    if (unpaidCount > 0) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: BrandColors.surface,
          title: Row(
            children: [
              const Icon(Icons.refresh, color: BrandColors.unpaid, size: 24),
              const SizedBox(width: 12),
              const Text('Schichtende nicht möglich', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Es sind noch nicht bezahlte Jacken im System. Diese müssen zuerst bezahlt werden, bevor die Schicht beendet werden kann.',
            style: TextStyle(color: Colors.white70)
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.active,
                foregroundColor: Colors.white,
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
      context: context,showLostAndFoundSheet
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BrandColors.surface,
        title: Row(
          children: [
            const Icon(Icons.refresh, color: BrandColors.unpaid, size: 24),
            const SizedBox(width: 12),
            const Text('Schichtende', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text('Sollen $archiveCount Jacken ins FUNDBÜRO verschoben und die Garderrobe geschlossen werden?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.unpaid, foregroundColor: Colors.white),
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

  void _zeigeFundbuero() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrandColors.background,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: BrandColors.forgotten, size: 24),
                    const SizedBox(width: 12),
                    const Text('Fundbüro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _syncMonitor(-1, 'recovery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.active,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('Ticket wiederherstellen', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white24),
            Expanded(
              child: StreamBuilder<List<LostItem>>(
                stream: _syncService.watchLostItems(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) return const Center(child: Text('Keine Gegenstände im Fundbüro.', style: TextStyle(color: Colors.grey)));
                  
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        color: BrandColors.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: BrandColors.forgotten,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${item.originalSlotId}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          title: const Text('Garderobenplatz', style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                            '${item.createdAt.day}.${item.createdAt.month}.${item.createdAt.year}',
                            style: const TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.active, foregroundColor: Colors.white),
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
        ),
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
          return Scaffold(
            backgroundColor: BrandColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: BrandColors.active),
                  if (_showTimeoutMessage) ...[
                    const SizedBox(height: 24),
                    const Text('Synchronisierung läuft...', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
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

        final totalPages = (allSlots.length / _itemsPerPage).ceil();
        final displaySlots = allSlots.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

        return Scaffold(
          backgroundColor: BrandColors.background,
          appBar: PreferredSize(
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
                    errorBuilder: (context, error, stackTrace) => const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white, fontSize: 14)),
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
          ),
          bottomNavigationBar: BottomAppBar(
            color: BrandColors.header,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.surface,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined, size: 16, color: BrandColors.forgotten),
                    label: const Text('Fundbüro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _zeigeFundbuero,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: BrandColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                        onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      ),
                      Text(
                        '${_currentPage + 1} / $totalPages',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                        onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.surface,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.refresh, size: 16, color: BrandColors.unpaid),
                    label: const Text('Schichtende', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _schichtBeendenDialog(allSlots),
                  ),
                ),
              ],
            ),
          ),
          body: GridView.builder(
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
                    child: Text(
                      '${slot.id}', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    )
                  ),
                ),
              );
            },
          ),
        );
      }
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
                      Text('Bügel ${slot.id}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
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
                              foregroundColor: Colors.white,
                              minimumSize: const Size(280, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 24, color: Colors.white12),
                      ],
                      const SizedBox(height: 8),
                      
                      if (slot.status == 'free') 
                        ListTile(
                          leading: const Icon(Icons.add_box, color: BrandColors.active), 
                          title: const Text('Jacke einchecken', style: TextStyle(color: Colors.white)), 
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
                          title: const Text('Kontaktloses bezahlen', style: TextStyle(color: Colors.white)), 
                          onTap: () async { 
                            final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'nfc', updatedAt: DateTime.now());
                            await _syncService.updateSlot(updated);
                            if (mounted) Navigator.pop(modalContext); 
                          }
                        ),
                        ListTile(
                          leading: const Icon(Icons.attach_money, color: Colors.amber), 
                          title: const Text('Bar bezahlen', style: TextStyle(color: Colors.white)), 
                          onTap: () async { 
                            final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'bar', updatedAt: DateTime.now());
                            await _syncService.updateSlot(updated);
                            if (mounted) Navigator.pop(modalContext); 
                          }
                        ),
                        ListTile(
                          leading: const Icon(Icons.credit_card, color: Colors.white),
                          title: const Text('SumUp bezahlen', style: TextStyle(color: Colors.white)), 
                          onTap: () async { 
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SumUp Integration folgt.'))
                            );
                          }
                        ),
                      ],
                      
                      if (slot.status == 'active' || slot.status == 'temporary') ...[
                        if (slot.status == 'active')
                          ListTile(
                            leading: const Icon(Icons.pause, color: Colors.orange), 
                            title: const Text('Temporärer Ausgang', style: TextStyle(color: Colors.white)), 
                            onTap: () async { 
                              final updated = slot.copyWith(status: 'temporary', updatedAt: DateTime.now());
                              await _syncService.updateSlot(updated);
                              if (mounted) Navigator.pop(modalContext); 
                            }
                          )
                        else
                          ListTile(
                            leading: const Icon(Icons.play_arrow, color: BrandColors.active), 
                            title: const Text('Wieder zurück', style: TextStyle(color: Colors.white)), 
                            onTap: () async { 
                              final updated = slot.copyWith(status: 'active', updatedAt: DateTime.now());
                              await _syncService.updateSlot(updated);
                              if (mounted) Navigator.pop(modalContext); 
                            }
                          ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red), 
                          title: const Text('Endgültig auschecken', style: TextStyle(color: Colors.white)), 
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
