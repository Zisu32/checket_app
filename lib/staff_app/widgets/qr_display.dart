import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/brand_colors.dart';

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
    final path = web.window.location.pathname.replaceAll('/staff/', '/');
    
    String qrData;
    if (isRecovery) {
      qrData = '$origin$path'; // Base website
    } else {
      qrData = '$origin$path?id=$ticketId&secret=$secret';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isRecovery ? 'TICKET WIEDERHERSTELLEN' : 'TICKET $ticketId',
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: BrandColors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isRecovery ? 'BITTE BASIS-URL SCANNEN' : 'BITTE SCANNEN',
          style: const TextStyle(
            fontSize: 18,
            color: BrandColors.free,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BrandColors.white,
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
          style: const TextStyle(color: BrandColors.free, fontSize: 16),
        ),
      ],
    );
  }
}
