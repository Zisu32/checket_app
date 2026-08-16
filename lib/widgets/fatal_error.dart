import 'package:flutter/material.dart';
import '../shared/theme/app_theme.dart';

class FatalError extends StatelessWidget {
  final FlutterErrorDetails details;
  final String? titleSuffix;

  const FatalError({
    super.key,
    required this.details,
    this.titleSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.unpaid, size: 48),
                const SizedBox(height: 20),
                Text(
                  'Startfehler oder Absturz${titleSuffix != null ? ' ($titleSuffix)' : ''}:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.medium,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${details.exception}\n\n${details.stack}',
                  style: const TextStyle(color: AppTheme.unpaid, fontSize: AppTheme.small),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
