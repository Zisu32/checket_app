import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class PageIndicator extends StatelessWidget {
  final int totalSlots;
  final int itemsPerPage;
  final int currentPage;

  const PageIndicator({
    super.key,
    required this.totalSlots,
    required this.itemsPerPage,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalSlots / itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentPage == index ? AppTheme.white : AppTheme.free,
            ),
          );
        }),
      ),
    );
  }
}
