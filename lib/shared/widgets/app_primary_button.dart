import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppPrimaryButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const AppPrimaryButton({
    super.key,
    this.text,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      child: icon != null
          ? Icon(icon, color: AppTheme.white, size: 20)
          : Text(
              text ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.small,
              ),
            ),
    );
  }
}
