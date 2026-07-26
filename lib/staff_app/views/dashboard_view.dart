import 'dart:async';
import 'dart:math';
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

  // Image-based Brand Colors
  static const Color brandBackground = Color(0xFF1A2229);
  static const Color brandActiveGreen = Color(0xFF2ABB85);
  static const Color brandButtonBase = Color(0xFF2C3E50);

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

  String _generateSecret() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _schichtBeendenDialog(List<WardrobeSlot> allSlots) {
    final occupiedCount = allSlots.where((s) => s.status != 'free').length;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: brandButtonBase,
        title: const Text('Schicht beenden?', style: TextStyle(color: Colors.white)),
        content: Text('Sollen die $occupiedCount belegten Bügel ins FUNDBÜRO verschoben und das Raster geleert werden?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
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
      backgroundColor: brandBackground,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Digitales Fundbüro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
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
                        color: brandButtonBase,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            child: Text('${item.originalSlotId}', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text('Bügel ${item.originalSlotId}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text('Vom: ${item.createdAt.day}.${item.createdAt.month}. ${item.createdAt.hour}:${item.createdAt.minute} Uhr', style: const TextStyle(color: Colors.white70)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: brandActiveGreen, foregroundColor: Colors.white),
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
            backgroundColor: brandBackground,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: brandActiveGreen),
                  if (_showTimeoutMessage) ...[
                    const SizedBox(height: 24),
                    const Text('Synchronisierung läuft...', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _syncService.pullFromSupabase(),
                      child: const Text('Manueller Reload', style: TextStyle(color: brandActiveGreen)),
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
          backgroundColor: brandBackground,
          appBar: AppBar(
            backgroundColor: brandBackground,
            elevation: 0,
            toolbarHeight: 70,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: brandButtonBase,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Seite ${_currentPage + 1} / $totalPages',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  ),
                ],
              ),
            ),
            centerTitle: true,
            leadingWidth: 150,
            leading: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandButtonBase,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.blueAccent),
                label: const Text('Fundbüro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _zeigeFundbuero,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandButtonBase,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.nightlight_round, size: 16, color: Colors.orangeAccent),
                  label: const Text('Schichtwechsel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _schichtBeendenDialog(allSlots),
                ),
              ),
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
              Color kachelFarbe = brandButtonBase;
              
              if (slot.status == 'unpaid') kachelFarbe = Colors.red.shade900;
              if (slot.status == 'active') kachelFarbe = brandActiveGreen;
              if (slot.status == 'temporary') kachelFarbe = Colors.orange.shade900;
              if (slot.status == 'forgotten') kachelFarbe = Colors.blueGrey.shade800;

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

  void _zeigeAktionen(BuildContext context, WardrobeSlot slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: brandBackground,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bügel ${slot.id} verwalten', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              
              if (slot.status == 'free') 
                ListTile(
                  leading: const Icon(Icons.add_box, color: Colors.blue), 
                  title: const Text('Jacke einchecken', style: TextStyle(color: Colors.white)), 
                  onTap: () async { 
                    final updated = slot.copyWith(
                      status: 'unpaid', 
                      secret: _generateSecret(),
                      isPaid: false,
                      paymentMethod: 'none',
                      updatedAt: DateTime.now()
                    );
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
                
              if (slot.status == 'unpaid') ...[
                ListTile(
                  leading: const Icon(Icons.contactless_outlined, color: brandActiveGreen), 
                  title: const Text('NFC Tap-to-Pay', style: TextStyle(color: Colors.white)), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'nfc', updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.amber), 
                  title: const Text('Bar bezahlt', style: TextStyle(color: Colors.white)), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'bar', updatedAt: DateTime.now());
                    await _syncService.updateSlot(updated);
                    if (mounted) Navigator.pop(modalContext); 
                  }
                ),
              ],
              
              if (slot.status == 'active') ...[
                ListTile(
                  leading: const Icon(Icons.pause, color: Colors.orange), 
                  title: const Text('Temporärer Ausgang', style: TextStyle(color: Colors.white)), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'temporary', updatedAt: DateTime.now());
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
              
              if (slot.status == 'temporary') 
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: brandActiveGreen), 
                  title: const Text('Wieder zurück', style: TextStyle(color: Colors.white)), 
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
