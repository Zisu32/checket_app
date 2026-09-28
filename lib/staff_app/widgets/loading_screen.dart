import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  final bool showTimeoutMessage;
  final VoidCallback onManualReload;
  final String? error;

  const LoadingScreen({
    super.key,
    required this.showTimeoutMessage,
    required this.onManualReload,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) ...[
              const Icon(Icons.cloud_off_rounded, color: AppTheme.unpaid, size: 48),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
              ),
            ] else
              const CircularProgressIndicator(color: AppTheme.active),
              
            if (showTimeoutMessage || error != null) ...[
              const SizedBox(height: 24),
              if (error == null)
                const Text(
                  'Synchronisierung läuft...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onManualReload,
                child: Text(
                  error != null ? 'Erneut versuchen' : 'Manueller Reload',
                  style: const TextStyle(color: AppTheme.active, fontSize: AppTheme.small),
                ),
              ),
            ],
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout_rounded, color: AppTheme.free),
              label: const Text('Abmelden', style: TextStyle(color: AppTheme.free)),
            ),
          ],
        ),
      ),
    );
  }
}
