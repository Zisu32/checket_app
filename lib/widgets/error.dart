import 'package:flutter/material.dart';
import '../shared/theme/brand_colors.dart';

class Error extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const Error({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: BrandColors.unpaid, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Initialisierungsfehler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: BrandColors.free, fontSize: 13),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Erneut versuchen'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
