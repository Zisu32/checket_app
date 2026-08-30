import 'package:flutter/material.dart';
import '../../../shared/database/database.dart';
import '../../../shared/services/sync_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_list_view.dart';
import '../../widgets/lost_found_action_sheet.dart';
import '../../../shared/widgets/app_thumb_button.dart';

class LostFoundTabView extends StatelessWidget {
  final SyncService syncService;
  final Function(String?, String, {String? groupId}) onSyncMonitor;

  const LostFoundTabView({
    super.key,
    required this.syncService,
    required this.onSyncMonitor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const AppHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Fundbüro',
            ),
            Expanded(
              child: StreamBuilder<List<LostItem>>(
                stream: syncService.watchLostItems(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  return AppListView<LostItem>(
                    items: items,
                    emptyMessage: 'Keine Gegenstände im Fundbüro',
                    titleBuilder: (item) => const Text('Platz', style: TextStyle(color: AppTheme.white, fontSize: AppTheme.small)),
                    subtitleBuilder: (item) {
                      final tag = item.createdAt.day.toString().padLeft(2, '0');
                      final monat = item.createdAt.month.toString().padLeft(2, '0');
                      final jahr = item.createdAt.year;
                      return Text('$tag.$monat.$jahr', style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.xsmall));
                    },
                    leadingBuilder: (item) => Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppTheme.forgotten, borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('${item.originalSlotId}',
                          style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: AppTheme.small))),
                    ),
                    trailingBuilder: (item) => IconButton(
                      icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => LostFoundActionSheet(
                            item: item,
                            syncService: syncService,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        AppThumbButton(
          icon: Icons.qr_code_scanner,
          onTap: () => onSyncMonitor('-1', 'recovery'),
        ),
      ],
    );
  }
}
