import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    // Theme wrapper for icons in the AppBar
    final iconTheme = IconTheme.of(context).copyWith(color: AppTheme.background);
    
    return AppBar(
      backgroundColor: AppTheme.header,
      elevation: 0,
      centerTitle: true,
      iconTheme: iconTheme,
      actionsIconTheme: iconTheme,
      leading: leading,
      title: SvgPicture.asset(
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
      actions: actions != null ? [...actions!, const SizedBox(width: 22)] : null,
    );
  }
}
