import 'package:flutter/material.dart';
import '../../shared/theme/brand_colors.dart';

class LoadingScreen extends StatelessWidget {
  final bool showTimeoutMessage;
  final VoidCallback onManualReload;

  const LoadingScreen({
    super.key,
    required this.showTimeoutMessage,
    required this.onManualReload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: BrandColors.active),
            if (showTimeoutMessage) ...[
              const SizedBox(height: 24),
              const Text(
                'Synchronisierung läuft...',
                textAlign: TextAlign.center,
                style: TextStyle(color: BrandColors.white),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onManualReload,
                child: const Text(
                  'Manueller Reload',
                  style: TextStyle(color: BrandColors.active),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
