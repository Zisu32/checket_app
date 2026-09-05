import 'package:flutter/material.dart';
import '../../../shared/database/database.dart';
import '../../../shared/theme/app_theme.dart';

class DashboardTabView extends StatelessWidget {
  final List<WardrobeSlot> slots;
  final PageController pageController;
  final int itemsPerPage;
  final Function(WardrobeSlot) onTap;
  final Set<int> selectedIds;
  final Function(int) onPageChanged;

  const DashboardTabView({
    super.key,
    required this.slots,
    required this.pageController,
    required this.itemsPerPage,
    required this.onTap,
    required this.selectedIds,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (slots.length / itemsPerPage).ceil();

    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: totalPages,
      itemBuilder: (context, pageIndex) {
        final displaySlots = slots.skip(pageIndex * itemsPerPage).take(itemsPerPage).toList();
        return GridView.builder(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 80),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 40,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 40,
          ),
          itemCount: displaySlots.length,
          itemBuilder: (context, index) {
            final slot = displaySlots[index];
            final isSelected = selectedIds.contains(slot.id);
            
            Color kachelFarbe = AppTheme.surface;
            if (slot.status == 'unpaid') kachelFarbe = AppTheme.unpaid;
            if (slot.status == 'active') kachelFarbe = AppTheme.active;
            if (slot.status == 'temporary') kachelFarbe = AppTheme.temporary;
            if (slot.status == 'forgotten') kachelFarbe = AppTheme.forgotten;
            if (slot.status == 'marked') kachelFarbe = AppTheme.background;
            
            // Selection override
            if (isSelected) kachelFarbe = AppTheme.background;

            final bool isMarked = slot.status == 'marked' || isSelected;
            final bool isUnpaid = slot.status == 'unpaid';

            return InkWell(
              key: ValueKey('slot_${slot.id}_${slot.status}_$isSelected'),
              onTap: () => onTap(slot),
              child: Container(
                decoration: BoxDecoration(
                  color: isUnpaid ? AppTheme.unpaid : (isMarked ? AppTheme.background : kachelFarbe), 
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${slot.id}', style: const TextStyle(fontSize: AppTheme.small, fontWeight: FontWeight.bold, color: AppTheme.white))
                ),
              ),
            );
          },
        );
      },
    );
  }
}
