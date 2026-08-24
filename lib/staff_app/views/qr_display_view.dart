import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/app_theme.dart';
import '../../shared/services/monitor_service.dart';
import '../widgets/qr_display.dart';

class QrDisplayView extends StatefulWidget {
  final int? ticketId;
  final String? groupId;
  final String? secret;

  const QrDisplayView({
    super.key,
    this.ticketId,
    this.groupId,
    this.secret,
  });

  @override
  State<QrDisplayView> createState() => _QrDisplayViewState();
}

class _QrDisplayViewState extends State<QrDisplayView> {
  int? _currentId;
  String? _currentGroupId;
  String? _currentSecret;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    web.document.title = 'Checket QR';

    // Identify which workstation this monitor belongs to
    final fullUrl = web.window.location.href;
    final uri = Uri.parse(fullUrl);
    final targetId = uri.queryParameters['target'] ?? 'default';

    final monitor = MonitorService();
    monitor.init();

    if (widget.ticketId != null || widget.groupId != null && widget.secret != null) {
      _currentId = widget.ticketId;
      _currentGroupId = widget.groupId;
      _currentSecret = widget.secret;
    } else {
      final last = monitor.readLastKnown(targetId: targetId);
      _currentId = last.id;
      _currentGroupId = last.groupId;
      _currentSecret = last.secret;
    }

    _subscription = monitor.onUpdate.listen((data) {
      if (!mounted) return;

      // Filter messages intended for this specific monitor
      if (data['targetId'] != targetId) return;

      final rawId = data['id'];
      final newId = rawId is int ? rawId : (rawId as num?)?.toInt();
      final newGroupId = data['groupId'] as String?;
      final newSecret = data['secret'] as String?;

      setState(() {
        _currentId = newId;
        _currentGroupId = newGroupId;
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
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: AppTheme.header,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: SvgPicture.asset(
            'assets/images/full-icon.svg',
            height: 28,
            placeholderBuilder: (_) => const Text(
              'CHECKET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppTheme.white,
                fontSize: AppTheme.small,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
            child: QrDisplay(
              ticketId: _currentId, 
              groupId: _currentGroupId,
              secret: _currentSecret,
            ),
          ),
        ),
      ),
    );
  }
}
