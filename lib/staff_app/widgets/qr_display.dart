import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/app_theme.dart';

class QrDisplay extends StatelessWidget {
  final int? ticketId;
  final String? secret;

  const QrDisplay({
    super.key,
    required this.ticketId,
    required this.secret,
  });

  @override
  Widget build(BuildContext context) {
    final isRecovery = ticketId == -1 || secret == 'recovery';
    
    // Generate URL for QR
    final origin = web.window.location.origin;
    // Strip '/staff/' or '/staff' from the end of the pathname
    String path = web.window.location.pathname;
    if (path.endsWith('/staff/')) {
      path = path.substring(0, path.length - 7);
    } else if (path.endsWith('/staff')) {
      path = path.substring(0, path.length - 6);
    }

    // Ensure path ends with exactly one slash if it's not empty, or is just a slash
    if (!path.endsWith('/')) {
      path += '/';
    }

    final user = Supabase.instance.client.auth.currentUser;
    final tenant = user?.appMetadata['schema_name'] as String? ?? 'public';

    String qrData;
    if (isRecovery) {
      qrData = '$origin$path?tenant=$tenant'; // Base website with tenant
    } else {
      qrData = '$origin$path?id=$ticketId&secret=$secret&tenant=$tenant';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isRecovery ? 'TICKET WIEDERHERSTELLEN' : 'TICKET $ticketId',
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: AppTheme.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isRecovery ? 'BITTE BASIS-URL SCANNEN' : 'BITTE SCANNEN',
          style: const TextStyle(
            fontSize: 18,
            color: AppTheme.free,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.shortestSide * 0.6,
            gapless: false,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          isRecovery
              ? 'Dein Handy lädt dein Ticket automatisch aus dem Speicher.'
              : 'Dein digitales Ticket für die Garderobe.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
        ),
      ],
    );
  }
}
