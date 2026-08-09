import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class SnakingBorderPainter extends CustomPainter {
  final double rotation;
  final double borderRadius;

  SnakingBorderPainter({
    required this.rotation,
    this.borderRadius = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 4;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Colors.transparent,
          AppTheme.white,
          AppTheme.white,
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.28, 0.42],
        transform: GradientRotation(rotation),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant SnakingBorderPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
