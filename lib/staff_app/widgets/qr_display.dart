import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/app_theme.dart';

class QrDisplay extends StatelessWidget {
  final String? ticketId;
  final String? groupId;
  final String? secret;
  final bool isExpired;
  final bool isSuccess;

  const QrDisplay({
    super.key,
    this.ticketId,
    this.groupId,
    this.secret,
    this.isExpired = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSuccess) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.active, size: 120),
          const SizedBox(height: 20),
          const Text(
            'CHECK-IN ERFOLGREICH!',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.active),
          ),
          const SizedBox(height: 10),
          Text(
            'Bügel ${ticketId ?? ""}',
            style: const TextStyle(fontSize: 24, color: AppTheme.white),
          ),
        ],
      );
    }

    if (isExpired || secret == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off_outlined, color: AppTheme.free.withValues(alpha: 0.5), size: 100),
          const SizedBox(height: 20),
          Text(
            secret == null ? 'BEREIT FÜR SCAN' : 'CODE ABGELAUFEN',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.free.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          Text(
            secret == null ? 'Warte auf nächsten Gast...' : 'Bitte das Personal fragen.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: AppTheme.free),
          ),
        ],
      );
    }

    final isRecovery = ticketId == '-1' || secret == 'recovery';
    final origin = web.window.location.origin;
    String path = web.window.location.pathname;
    if (path.endsWith('/staff/')) path = path.substring(0, path.length - 7);
    else if (path.endsWith('/staff')) path = path.substring(0, path.length - 6);
    if (!path.endsWith('/')) path += '/';

    final user = Supabase.instance.client.auth.currentUser;
    final tenant = user?.appMetadata['schema_name'] as String? ?? 'public';

    String qrData;
    if (isRecovery) {
      qrData = '$origin$path?tenant=$tenant';
    } else if (groupId != null && groupId!.isNotEmpty) {
      qrData = '$origin$path?groupId=$groupId&secret=$secret&tenant=$tenant';
    } else {
      final idOnly = ticketId?.split(',').first.trim() ?? '';
      qrData = '$origin$path?id=$idOnly&secret=$secret&tenant=$tenant';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isRecovery 
            ? 'TICKET WIEDERHERSTELLEN' 
            : (groupId != null && groupId!.isNotEmpty ? 'GRUPPEN-TICKET' : 'TICKET $ticketId'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppTheme.white, letterSpacing: 2),
        ),
        if (groupId != null && groupId!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              ticketId ?? '',
              style: const TextStyle(fontSize: 32, color: AppTheme.white, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        const SizedBox(height: 10),
        const Text('BITTE SCANNEN', style: TextStyle(fontSize: 18, color: AppTheme.active, letterSpacing: 4)),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(24)),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.shortestSide * 0.6,
            gapless: false,
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Dein digitales Ticket für die Garderobe.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
        ),
      ],
    );
  }
}
