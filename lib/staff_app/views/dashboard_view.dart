import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final _syncService = SyncService();
  bool _showTimeoutMessage = false;
  Timer? _timeoutTimer;
  
  int _currentPage = 0;
  final int _itemsPerPage = 100;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showTimeoutMessage = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _schichtBeendenDialog(List<WardrobeSlot> allSlots) {
    final occupiedCount = allSlots.where((s) => s.status != 'free').length;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schicht beenden?'),
        content: Text('Sollen die $occupiedCount belegten Bügel ins FUNDBÜRO verschoben und das Raster geleert werden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900),
            onPressed: () async {
              await _syncService.archiveAndResetShift();
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Ja, Schicht beenden'),
          ),
        ],
      ),
    );
  }

  void _zeigeFundbuero() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Digitales Fundbüro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),
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
                        color: Colors.white.withValues(alpha: 0.05),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            child: Text('${item.originalSlotId}', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text('Bügel ${item.originalSlotId}'),
                          subtitle: Text('Vom: ${item.createdAt.day}.${item.createdAt.month}. ${item.createdAt.hour}:${item.createdAt.minute} Uhr'),
                          trailing: ElevatedButton(
                            onPressed: () => _syncService.handOverLostItem(item),
                            child: const Text('Aushändigen'),
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (_showTimeoutMessage) ...[
                    const SizedBox(height: 24),
                    const Text('Synchronisierung läuft...', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _syncService.pullFromSupabase(),
                      child: const Text('Manueller Reload'),
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
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                ),
                Text('Seite ${_currentPage + 1} / $totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.inventory_2_outlined, color: Colors.blueAccent), 
              onPressed: _zeigeFundbuero
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.nightlight_round, color: Colors.orangeAccent), 
                onPressed: () => _schichtBeendenDialog(allSlots)
              )
            ],
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
              Color kachelFarbe = const Color(0xFF2C2C2C);
              
              if (slot.status == 'unpaid') kachelFarbe = Colors.red.shade900;
              if (slot.status == 'active') kachelFarbe = Colors.green.shade800;
              if (slot.status == 'temporary') kachelFarbe = Colors.orange.shade900;
              if (slot.status == 'forgotten') kachelFarbe = Colors.blueGrey.shade800;

              return InkWell(
                onTap: () => _zeigeAktionen(context, slot),
                child: Container(
                  decoration: BoxDecoration(color: kachelFarbe, borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                      '${slot.id}', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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

  void _zeigeAktionen(BuildContext context, WardrobeSlot slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bügel ${slot.id} verwalten', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (slot.status == 'free') 
                ListTile(
                  leading: const Icon(Icons.add_box, color: Colors.blue), 
                  title: const Text('Jacke einchecken'), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'unpaid', updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
                
              if (slot.status == 'unpaid') ...[
                ListTile(
                  leading: const Icon(Icons.contactless_outlined, color: Colors.green), 
                  title: const Text('NFC Tap-to-Pay'), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'active', isPaid: true, updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.amber), 
                  title: const Text('Bar bezahlt'), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'active', isPaid: true, updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
              ],
              
              if (slot.status == 'active') ...[
                ListTile(
                  leading: const Icon(Icons.pause, color: Colors.orange), 
                  title: const Text('Temporärer Ausgang'), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'temporary', updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red), 
                  title: const Text('Endgültig auschecken'), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'free', isPaid: false, updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
              ],
              
              if (slot.status == 'temporary') 
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.green), 
                  title: const Text('Wieder zurück'), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'active', updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
            ],
          ),
        );
      },
    );
  }
}
