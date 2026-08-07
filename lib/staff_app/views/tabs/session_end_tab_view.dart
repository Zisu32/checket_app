import 'package:flutter/material.dart';
import '../../../shared/database/database.dart';
import '../../../shared/services/sync_service.dart';
import '../../../shared/theme/brand_colors.dart';

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
    final archiveCount = allSlots.where((s) => s.status == 'active' || s.status == 'temporary').length;
    
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.loop, color: BrandColors.white, size: 28),
            ],
          ),
        ),
        const Divider(height: 1, color: BrandColors.surface),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Schicht beenden?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: BrandColors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sollen $archiveCount Jacken ins FUNDBÜRO verschoben und die Garderobe geschlossen werden?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BrandColors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.unpaid,
                      foregroundColor: BrandColors.white,
                      minimumSize: const Size(240, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await syncService.archiveAndResetShift();
                      onComplete();
                    },
                    child: const Text('Ja, Schicht beenden', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
