import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/app_theme.dart';

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
      backgroundColor: AppTheme.header,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/full-icon.svg',
            height: 28,
            placeholderBuilder: (_) => const Text(
              'CHECKET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppTheme.white,
                fontSize: AppTheme.small,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<SyncStatus>(
            valueListenable: syncService.statusNotifier,
            builder: (context, status, _) {
              Color statusColor = AppTheme.active;
              if (status == SyncStatus.syncing) statusColor = AppTheme.temporary;
              if (status == SyncStatus.offline) statusColor = AppTheme.unpaid;

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
