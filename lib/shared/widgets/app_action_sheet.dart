import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SheetAction {
  final Widget? leading;
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  SheetAction({
    this.leading,
    this.icon,
    required this.label,
    this.color = AppTheme.white,
    this.onTap,
  });
}

class AppActionSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<SheetAction>? actions;
  final Widget? body;

  const AppActionSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.body,
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
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: AppTheme.medium,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
          const SizedBox(height: 16),
          if (body != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: body!,
          ),
          if (actions != null)
            ...actions!.map((action) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: action.leading ?? (action.icon != null ? Icon(action.icon, color: action.color) : null),
                  title: Text(
                    action.label, 
                    style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small)
                  ),
                  onTap: action.onTap,
                )),
        ],
      ),
    );
  }
}
