import 'package:flutter/material.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/brand_colors.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final SyncService syncService;
  final Animation<double> pulseAnimation;

  const TopBar({
    super.key,
    required this.syncService,
    required this.pulseAnimation,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: BrandColors.header,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/full-icon.png',
            height: 28,
            errorBuilder: (_, __, ___) => const Text(
              'CHECKET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: BrandColors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<SyncStatus>(
            valueListenable: syncService.statusNotifier,
            builder: (context, status, _) {
              Color statusColor = BrandColors.active;
              if (status == SyncStatus.syncing) statusColor = BrandColors.temporary;
              if (status == SyncStatus.offline) statusColor = BrandColors.unpaid;

              return AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(alpha: pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: pulseAnimation.value * 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      automaticallyImplyLeading: false,
    );
  }
}
