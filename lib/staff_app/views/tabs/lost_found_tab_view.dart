import 'package:flutter/material.dart';
import '../../../shared/database/database.dart';
import '../../../shared/services/sync_service.dart';
import '../../../shared/theme/app_theme.dart';

class LostFoundTabView extends StatelessWidget {
  final SyncService syncService;
  final Function(int, String) onSyncMonitor;

  const LostFoundTabView({
    super.key,
    required this.syncService,
    required this.onSyncMonitor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppTheme.white,
                    size: 28),
                AppTheme.buildPrimaryButton(
                  text: 'Ticket wiederherstellen',
                  color: AppTheme.active,
                  onTap: () => onSyncMonitor(-1, 'recovery'),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
        Expanded(
          child: StreamBuilder<List<LostItem>>(
            stream: syncService.watchLostItems(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text(
                  'Keine Gegenstände im Fundbüro',
                  style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final tag = item.createdAt.day.toString().padLeft(2, '0');
                  final monat = item.createdAt.month.toString().padLeft(2, '0');
                  final jahr = item.createdAt.year;

                  return Card(
                    color: AppTheme.surface,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppTheme.forgotten,
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text('${item.originalSlotId}',
                            style: const TextStyle(color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18))),
                      ),
                      title: const Text('Platz', style: TextStyle(
                          color: AppTheme.white, fontSize: AppTheme.small)),
                      subtitle: Text(
                          '$tag.$monat.$jahr', style: const TextStyle(
                          color: AppTheme.free, fontSize: AppTheme.small)),
                      trailing: AppTheme.buildPrimaryButton(
                        text: 'Aushändigen',
                        color: AppTheme.active,
                        onTap: () => syncService.handOverLostItem(item),
                        width: 100,
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
}
