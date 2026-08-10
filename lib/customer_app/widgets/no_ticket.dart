import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/theme/app_theme.dart';

class NoTicket extends StatelessWidget {
  const NoTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/full-icon.svg',
                height: 50,
                placeholderBuilder: (_) => const Text(
                  'CHECKET',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.medium,
                    color: AppTheme.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Icon(Icons.search_off, color: AppTheme.free, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Kein aktives Ticket gefunden',
                style: TextStyle(fontSize: AppTheme.medium, fontWeight: FontWeight.bold, color: AppTheme.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bitte scanne den QR-Code oder wende dich an das Personal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
