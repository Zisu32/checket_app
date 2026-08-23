import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppThumbButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const AppThumbButton({
    super.key,
    this.icon = Icons.add,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 28,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.active,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppTheme.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
