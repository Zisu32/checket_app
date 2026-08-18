import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/theme/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.unpaid, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Initialisierungsfehler',
                style: TextStyle(fontSize: AppTheme.medium, fontWeight: FontWeight.bold, color: AppTheme.white),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
              ),
              const SizedBox(height: 48),
              AppTheme.buildPrimaryButton(
                text: 'Erneut versuchen',
                color: AppTheme.active,
                onTap: onRetry,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.free),
                label: const Text('Abmelden', style: TextStyle(color: AppTheme.free)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
