import 'package:flutter/material.dart';
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/app_theme.dart';

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
            'Platz ${item.originalSlotId} bearbeiten',
            style: const TextStyle(
              fontSize: AppTheme.medium,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call_missed_outgoing, color: AppTheme.active),
              title: const Text('Aushändigen', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)),
              onTap: () async {
                await syncService.handOverLostItem(item);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
