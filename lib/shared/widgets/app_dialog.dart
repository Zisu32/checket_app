import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? body;
  final List<Widget> actions;
  final MainAxisAlignment actionsAlignment;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.body,
    required this.actions,
    this.actionsAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: AppTheme.medium,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 16),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: AppTheme.small,
                ),
              ),
            ],
            if (body != null) ...[
              const SizedBox(height: 24),
              body!,
            ],
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
