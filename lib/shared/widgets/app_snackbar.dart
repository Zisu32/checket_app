import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSnackBar extends SnackBar {
  AppSnackBar({
    super.key,
    required String message,
    bool isError = true,
  }) : super(
          content: Text(
            message,
            style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
          ),
          backgroundColor: isError ? AppTheme.unpaid : AppTheme.active,
          behavior: SnackBarBehavior.fixed,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        );
}
