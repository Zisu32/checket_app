import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/brand_colors.dart';
import '../../shared/services/monitor_service.dart';
import '../widgets/qr_viewer.dart';

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
            errorBuilder: (context, error, stackTrace) => const Text('CHECKET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: BrandColors.white, fontSize: 14)),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
            child: QrViewer(ticketId: _currentId, secret: _currentSecret),
          ),
        ),
      ),
    );
  }
}
