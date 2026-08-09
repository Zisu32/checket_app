import 'package:flutter/material.dart';
import '../../../shared/database/database.dart';
import '../../../shared/services/sync_service.dart';
import '../../../shared/theme/app_theme.dart';

class SessionEndTabView extends StatelessWidget {
  final List<WardrobeSlot> allSlots;
  final SyncService syncService;
  final VoidCallback onComplete;

  const SessionEndTabView({
    super.key,
    required this.allSlots,
    required this.syncService,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final activeJacketsCount = allSlots
        .where((s) => s.status == 'active')
        .length;

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: const [
                Icon(Icons.loop, color: AppTheme.white, size: 28),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Schicht beenden?',
                    style: TextStyle(fontSize: AppTheme.medium,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sollen $activeJacketsCount aktive Jacken ins FUNDBÜRO verschoben und die Garderobe geschlossen werden?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.white, fontSize: AppTheme.small),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.unpaid,
                      foregroundColor: AppTheme.white,
                      minimumSize: const Size(240, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await syncService.archiveAndResetShift();
                      onComplete();
                    },
                    child: const Text('Ja, Schicht beenden', style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: AppTheme.small)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onComplete,
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        color: AppTheme.free,
                        fontSize: AppTheme.small,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
