import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/theme/app_theme.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final SyncService syncService;
  final Animation<double> pulseAnimation;
  final bool showSettings;
  final Widget? leading;
  final Widget? trailing;

  const TopBar({
    super.key,
    required this.syncService,
    required this.pulseAnimation,
    this.showSettings = true,
    this.leading,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  void _showSettingsAuth(BuildContext context) {
    final email = syncService.supabase.auth.currentUser?.email ?? "";
    final passwordController = TextEditingController();
    bool isAuthenticating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text(
            'Zugriff geschützt',
            style: TextStyle(color: AppTheme.white, fontSize: AppTheme.medium, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anmeldung erforderlich für: \n$email', style: const TextStyle(color: AppTheme.free)),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(color: AppTheme.white),
                cursorColor: AppTheme.white,
                decoration: const InputDecoration(
                  labelText: 'Passwort eingeben',
                  labelStyle: TextStyle(color: AppTheme.free),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.active)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: AppTheme.free)),
            ),
            isAuthenticating
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.active)),
                  )
                : AppTheme.buildPrimaryButton(
                    text: 'Bestätigen',
                    color: AppTheme.active,
                    onTap: () async {
                      setDialogState(() => isAuthenticating = true);
                      final success = await syncService.reauthenticate(passwordController.text);
                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings');
                        }
                      } else {
                        setDialogState(() => isAuthenticating = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passwort falsch'), backgroundColor: AppTheme.unpaid),
                          );
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.header,
      elevation: 0,
      centerTitle: true,
      leading: leading,
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
      automaticallyImplyLeading: leading != null,
      actions: [
        if (trailing != null) ...[
          trailing!,
          const SizedBox(width: 8),
        ] else if (showSettings) ...[
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.background, size: 26),
            onPressed: () => _showSettingsAuth(context),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}
