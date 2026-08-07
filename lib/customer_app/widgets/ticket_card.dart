import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/theme/brand_colors.dart';
import 'snaking_border_painter.dart';

class TicketCard extends StatelessWidget {
  final Color statusColor;
  final IconData statusIcon;
  final String statusText;
  final int ticketId;
  final bool isSearching;
  final bool isShortScreen;
  final Animation<double> pulseAnimation;
  final AnimationController borderRotationController;

  const TicketCard({
    super.key,
    required this.statusColor,
    required this.statusIcon,
    required this.statusText,
    required this.ticketId,
    required this.isSearching,
    required this.isShortScreen,
    required this.pulseAnimation,
    required this.borderRotationController,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(isShortScreen ? 20 : 32),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.shadow.withValues(
                        alpha: 0.3 + (pulseAnimation.value * 0.3),
                      ),
                      blurRadius: 10 + (pulseAnimation.value * 10),
                      spreadRadius: pulseAnimation.value * 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSearching)
                      const CircularProgressIndicator(color: BrandColors.white)
                    else ...[
                      Icon(statusIcon, color: BrandColors.white, size: isShortScreen ? 48 : 64),
                      const SizedBox(height: 8),
                      Text(statusText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: BrandColors.white)),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$ticketId',
                          style: TextStyle(
                            fontSize: isShortScreen ? 80 : 110,
                            fontWeight: FontWeight.w900,
                            color: BrandColors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Snaking white border
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: borderRotationController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: SnakingBorderPainter(
                      rotation: borderRotationController.value * 2 * math.pi,
                      borderRadius: 24,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
