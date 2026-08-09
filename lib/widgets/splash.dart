import 'package:flutter/material.dart';
import '../shared/theme/brand_colors.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/full-icon.png',
              height: 60,
              errorBuilder: (_, __, ___) => const Text(
                'CHECKET',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: BrandColors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: BrandColors.active),
          ],
        ),
      ),
    );
  }
}
