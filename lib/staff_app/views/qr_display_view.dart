import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/brand_colors.dart';

class QrDisplayView extends StatelessWidget {
  final int ticketId;
  final String secret;

  const QrDisplayView({
    super.key,
    required this.ticketId,
    required this.secret,
  });

  @override
  Widget build(BuildContext context) {
    final isRecovery = ticketId == -1 || secret == 'recovery';
    
    // Determine the URL for the QR code
    String qrData;
    if (isRecovery) {
      // Points to base website only (no parameters)
      qrData = web.window.location.origin + web.window.location.pathname.replaceAll('/staff/', '/');
    } else {
      // Points to specific ticket with secret
      final baseUrl = web.window.location.origin + web.window.location.pathname.replaceAll('/staff/', '/');
      qrData = '$baseUrl?id=$ticketId&secret=$secret';
    }

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/full-icon.png',
                height: 80,
                errorBuilder: (_, __, ___) => const Icon(Icons.checkroom, color: Colors.white, size: 80),
              ),
              const SizedBox(height: 40),
              Text(
                isRecovery ? 'TICKET WIEDERHERSTELLEN' : 'TICKET #$ticketId',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isRecovery ? 'BITTE BASIS-URL SCANNEN' : 'BITTE SCANNEN',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white54,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: MediaQuery.of(context).size.shortestSide * 0.5,
                  gapless: false,
                ),
              ),
              const SizedBox(height: 50),
              Text(
                isRecovery 
                  ? 'Dein Handy lädt dein Ticket automatisch aus dem Speicher.' 
                  : 'Dein digitales Ticket für die Garderobe.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
