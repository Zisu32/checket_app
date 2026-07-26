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

  void _schliesseGarderobeUndFeierabend(List<WardrobeSlot> slots) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Garderobe schließen?'),
        content: const Text('Alle noch belegten Bügel werden als "VERGESSEN" markiert. Kunden erhalten automatisch eine Push-Benachrichtigung.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              for (var slot in slots) {
                if (slot.status == 'active' || slot.status == 'temporary') {
                  final updated = slot.copyWith(status: 'forgotten', updatedAt: DateTime.now());
                  await _syncService.updateSlot(updated);
                }
              }
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Ja, Feierabend!'),
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
        final slots = snapshot.data ?? [];
        
        if (slots.isEmpty) {
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

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: const Text('Checket - Garderoben-Manager'),
            backgroundColor: const Color(0xFF1E1E1E),
            actions: [
              IconButton(
                icon: const Icon(Icons.nightlight_round, color: Colors.orangeAccent), 
                onPressed: () => _schliesseGarderobeUndFeierabend(slots)
              )
            ],
          ),
          body: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, 
              crossAxisSpacing: 8, 
              mainAxisSpacing: 8
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              Color kachelFarbe = const Color(0xFF2C2C2C);
              
              if (slot.status == 'unpaid') kachelFarbe = Colors.red.shade900;
              if (slot.status == 'active') kachelFarbe = Colors.green.shade800;
              if (slot.status == 'temporary') kachelFarbe = Colors.orange.shade900;
              if (slot.status == 'forgotten') kachelFarbe = Colors.blueGrey.shade800;

              return InkWell(
                onTap: () => _zeigeAktionen(context, slot),
                child: Container(
                  decoration: BoxDecoration(color: kachelFarbe, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('${slot.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
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
                
              if (slot.status == 'forgotten') 
                ListTile(
                  leading: const Icon(Icons.assignment_turned_in, color: Colors.teal), 
                  title: const Text('Aus Fundbüro übergeben'), 
                  onTap: () async { 
                    final updated = slot.copyWith(status: 'free', isPaid: false, updatedAt: DateTime.now());
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
