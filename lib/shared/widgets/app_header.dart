import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_primary_button.dart';

class AppHeader extends StatelessWidget {
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Color actionColor;

  const AppHeader({
    super.key,
    required this.icon,
    this.actionText,
    this.onActionTap,
    this.actionColor = AppTheme.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppTheme.white, size: 28),
                if (actionText != null && onActionTap != null)
                  AppPrimaryButton(
                    text: actionText!,
                    color: actionColor,
                    onTap: onActionTap!,
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
      ],
    );
  }
}
