import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/app_theme.dart';

class QrDisplay extends StatelessWidget {
  final String? ticketId;
  final String? groupId;
  final String? secret;

  const QrDisplay({
    super.key,
    this.ticketId,
    this.groupId,
    this.secret,
  });

  @override
  Widget build(BuildContext context) {
    final isRecovery = ticketId == '-1' || secret == 'recovery';
    
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
    } else if (groupId != null && groupId!.isNotEmpty) {
      qrData = '$origin$path?groupId=$groupId&secret=$secret&tenant=$tenant';
    } else {
      // For single tickets, clean the label to ensure it's just the ID
      final idOnly = ticketId?.split(',').first.trim() ?? '';
      qrData = '$origin$path?id=$idOnly&secret=$secret&tenant=$tenant';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isRecovery 
            ? 'TICKET WIEDERHERSTELLEN' 
            : (groupId != null && groupId!.isNotEmpty ? 'GRUPPEN-TICKET $ticketId' : 'TICKET $ticketId'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: AppTheme.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isRecovery ? 'BITTE SCANNEN' : 'BITTE SCANNEN',
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
              ? 'Dein Smartphone lädt dein Ticket automatisch.'
              : 'Dein digitales Ticket für die Garderobe.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
        ),
      ],
    );
  }
}
