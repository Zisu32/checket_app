import 'package:flutter/material.dart';
import '../../../shared/database/database.dart';
import '../../../shared/theme/brand_colors.dart';

class DashboardTabView extends StatelessWidget {
  final List<WardrobeSlot> slots;
  final PageController pageController;
  final int itemsPerPage;
  final Function(WardrobeSlot) onTap;
  final Function(int) onPageChanged;

  const DashboardTabView({
    super.key,
    required this.slots,
    required this.pageController,
    required this.itemsPerPage,
    required this.onTap,
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
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 40, 
            mainAxisSpacing: 6, 
            crossAxisSpacing: 6,
            mainAxisExtent: 40,
          ),
          itemCount: displaySlots.length,
          itemBuilder: (context, index) {
            final slot = displaySlots[index];
            Color kachelFarbe = BrandColors.surface;
            if (slot.status == 'unpaid') kachelFarbe = BrandColors.unpaid;
            if (slot.status == 'active') kachelFarbe = BrandColors.active;
            if (slot.status == 'temporary') kachelFarbe = BrandColors.temporary;
            if (slot.status == 'forgotten') kachelFarbe = BrandColors.forgotten;

            return InkWell(
              onTap: () => onTap(slot),
              child: Container(
                decoration: BoxDecoration(color: kachelFarbe, borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text('${slot.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BrandColors.white))
                ),
              ),
            );
          },
        );
      },
    );
  }
}
