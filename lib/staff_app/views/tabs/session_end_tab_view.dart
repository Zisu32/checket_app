import 'package:flutter/material.dart';
import '../../../shared/database/database.dart';
import '../../../shared/services/sync_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_primary_button.dart';

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
        const AppHeader(icon: Icons.swap_horiz_rounded),
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
                  AppPrimaryButton(
                    text: 'Ja, Schicht beenden',
                    color: AppTheme.unpaid,
                    onTap: () async {
                      try {
                        await syncService.archiveAndResetShift();
                        onComplete();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler: $e'));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onComplete,
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        color: AppTheme.free,
                        fontSize: AppTheme.small,
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
