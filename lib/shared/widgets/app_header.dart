import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final IconData icon;
  final String? title;

  const AppHeader({
    super.key,
    required this.icon,
    this.title,
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
              children: [
                Icon(icon, color: AppTheme.white, size: 28),
                if (title != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    title!,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: AppTheme.small,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
      ],
    );
  }
}
