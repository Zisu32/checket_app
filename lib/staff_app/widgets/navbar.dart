import 'package:flutter/material.dart';
import '../../shared/database/database.dart';
import '../../shared/theme/app_theme.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final List<WardrobeSlot> allSlots;
  final Function(int) onTabSelected;
  final VoidCallback onLockedTabClick;

  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.allSlots,
    required this.onTabSelected,
    required this.onLockedTabClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppTheme.header,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(0, Icons.inventory_2_outlined, 'Fundbüro'),
          _buildItem(1, Icons.grid_view_rounded, 'Dashboard'),
          _buildItem(2, Icons.loop, 'Schichtende'),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isActive = selectedIndex == index;
    final color = isActive ? AppTheme.white : AppTheme.surface;

    return InkWell(
      onTap: () {
        if (index == 2) {
          final unpaidCount = allSlots.where((s) => s.status == 'unpaid').length;
          if (unpaidCount > 0) {
            onLockedTabClick();
            return;
          }
        }
        onTabSelected(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: AppTheme.xsmall, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
