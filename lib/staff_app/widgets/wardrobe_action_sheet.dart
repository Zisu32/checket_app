import 'package:flutter/material.dart';
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/brand_colors.dart';

class WardrobeActionSheet extends StatefulWidget {
  final WardrobeSlot initialSlot;
  final SyncService syncService;
  final Function(int id, String secret) onSyncMonitor;
  final String Function() onGenerateSecret;

  const WardrobeActionSheet({
    super.key,
    required this.initialSlot,
    required this.syncService,
    required this.onSyncMonitor,
    required this.onGenerateSecret,
  });

  @override
  State<WardrobeActionSheet> createState() => _WardrobeActionSheetState();
}

class _WardrobeActionSheetState extends State<WardrobeActionSheet> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WardrobeSlot>>(
      stream: widget.syncService.watchSlots(),
      builder: (context, snapshot) {
        final slots = snapshot.data ?? [];
        final slot = slots.firstWhere((s) => s.id == widget.initialSlot.id, orElse: () => widget.initialSlot);

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bügel ${slot.id}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (slot.status == 'active' || slot.status == 'temporary' || slot.status == 'forgotten') ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onSyncMonitor(-1, 'recovery');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.qr_code_2, size: 20),
                    label: const Text(
                      'Ticket wiederherstellen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.active,
                      foregroundColor: BrandColors.white,
                      minimumSize: const Size(280, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    final secret = widget.onGenerateSecret();
                    final updated = slot.copyWith(
                      status: 'unpaid',
                      secret: secret,
                      isPaid: false,
                      paymentMethod: 'none',
                      updatedAt: DateTime.now(),
                    );

                    widget.onSyncMonitor(slot.id, secret);
                    await widget.syncService.updateSlot(updated);
                  },
                ),
              if (slot.status == 'unpaid') ...[
                ListTile(
                  leading: const Icon(Icons.contactless_outlined, color: BrandColors.active),
                  title: const Text('Kontaktloses bezahlen', style: TextStyle(color: BrandColors.white)),
                  onTap: () async {
                    final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'nfc', updatedAt: DateTime.now());
                    await widget.syncService.updateSlot(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.euro, color: BrandColors.secret),
                  title: const Text('Bar bezahlen', style: TextStyle(color: BrandColors.white)),
                  onTap: () async {
                    final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'bar', updatedAt: DateTime.now());
                    await widget.syncService.updateSlot(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
              if (slot.status == 'active' || slot.status == 'temporary') ...[
                if (slot.status == 'active')
                  ListTile(
                    leading: const Icon(Icons.pause, color: BrandColors.temporary),
                    title: const Text('Temporärer Ausgang', style: TextStyle(color: BrandColors.white)),
                    onTap: () async {
                      final updated = slot.copyWith(status: 'temporary', updatedAt: DateTime.now());
                      await widget.syncService.updateSlot(updated);
                      if (context.mounted) Navigator.pop(context);
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.play_arrow, color: BrandColors.active),
                    title: const Text('Wieder zurück', style: TextStyle(color: BrandColors.white)),
                    onTap: () async {
                      final updated = slot.copyWith(status: 'active', updatedAt: DateTime.now());
                      await widget.syncService.updateSlot(updated);
                      if (context.mounted) Navigator.pop(context);
                    },
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
                      updatedAt: DateTime.now(),
                    );
                    await widget.syncService.updateSlot(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
