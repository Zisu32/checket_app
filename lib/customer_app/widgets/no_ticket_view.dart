import 'package:flutter/material.dart';
import '../../shared/theme/brand_colors.dart';

class NoTicketView extends StatelessWidget {
  const NoTicketView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/full-icon.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const Text('CHECKET',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: BrandColors.white))),
              const SizedBox(height: 40),
              const Icon(Icons.search_off, color: BrandColors.free, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Kein aktives Ticket gefunden',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BrandColors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bitte scanne den QR-Code oder wende dich an das Personal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BrandColors.free, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
