import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/brand_colors.dart';
import '../../shared/services/monitor_service.dart';

class QrDisplayView extends StatefulWidget {
  final int? ticketId;
  final String? secret;

  const QrDisplayView({
    super.key,
    this.ticketId,
    this.secret,
  });

  @override
  State<QrDisplayView> createState() => _QrDisplayViewState();
}

class _QrDisplayViewState extends State<QrDisplayView> {
  int? _currentId;
  String? _currentSecret;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    web.document.title = 'Checket Monitor';

    final monitor = MonitorService();
    monitor.init();

    if (widget.ticketId != null && widget.secret != null) {
      _currentId = widget.ticketId;
      _currentSecret = widget.secret;
    } else {
      final last = monitor.readLastKnown();
      _currentId = last.id;
      _currentSecret = last.secret;
    }

    _subscription = monitor.onUpdate.listen((data) {
      if (!mounted) return;

      final rawId = data['id'];
      final newId = rawId is int ? rawId : (rawId as num?)?.toInt();
      final newSecret = data['secret'] as String?;

      setState(() {
        _currentId = newId;
        _currentSecret = newSecret;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecovery = _currentId == -1 || _currentSecret == 'recovery';
    
    // Generate URL for QR
    final origin = web.window.location.origin;
    final path = web.window.location.pathname.replaceAll('/staff/', '/');
    
    String qrData;
    if (isRecovery) {
      qrData = '$origin$path'; // Base website
    } else {
      qrData = '$origin$path?id=$_currentId&secret=$_currentSecret';
    }

    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: BrandColors.header,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Image.asset(
            'assets/images/full-icon.png', 
            height: 28,
            errorBuilder: (context, error, stackTrace) => const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white, fontSize: 14)),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isRecovery ? 'TICKET WIEDERHERSTELLEN' : 'TICKET $_currentId',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isRecovery ? 'BITTE SCANNEN' : 'BITTE SCANNEN',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white54,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
