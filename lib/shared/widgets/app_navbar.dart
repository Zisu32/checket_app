import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavbarItem {
  final IconData icon;
  final String label;
  final Future<bool> Function()? onBeforeTap;

  NavbarItem({
    required this.icon,
    required this.label,
    this.onBeforeTap,
  });
}

class AppNavbar extends StatelessWidget {
  final int selectedIndex;
  final List<NavbarItem> items;
  final Function(int) onTabSelected;

  const AppNavbar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppTheme.header,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) => _buildItem(index, items[index])),
      ),
    );
  }

  Widget _buildItem(int index, NavbarItem item) {
    final isActive = selectedIndex == index;
    final color = isActive ? AppTheme.white : AppTheme.surface;

    return InkWell(
      onTap: () async {
        if (item.onBeforeTap != null) {
          final allow = await item.onBeforeTap!();
          if (!allow) return;
        }
        onTabSelected(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.xsmall,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
