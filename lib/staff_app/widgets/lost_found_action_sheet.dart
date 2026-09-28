import 'package:flutter/material.dart';
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_action_sheet.dart';

class LostFoundActionSheet extends StatelessWidget {
  final LostItem item;
  final SyncService syncService;

  const LostFoundActionSheet({
    super.key,
    required this.item,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return AppActionSheet(
      title: 'Bügel ${item.originalSlotId}',
      subtitle: 'Fundsache verwalten',
      actions: [
        SheetAction(
          icon: Icons.call_missed_outgoing,
          label: 'Aushändigen',
          color: AppTheme.active,
          onTap: () async {
            await syncService.handOverLostItem(item);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
