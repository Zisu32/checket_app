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
  String? _currentId;
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
    
    // Identify workstation via window name (cleaner URL)
    String targetId = 'default';
    final windowName = web.window.name;
    
    if (windowName.startsWith('checket_monitor_')) {
      targetId = windowName.replaceFirst('checket_monitor_', '');
    } else {
      // Fallback to URL parameters for manual input
      Map<String, String> params = Map.from(uri.queryParameters);
      if (uri.hasFragment) {
        final fragment = uri.fragment.contains('?') ? uri.fragment.split('?').last : '';
        if (fragment.isNotEmpty) {
          params.addAll(Uri.splitQueryString(fragment));
        }
      }
      targetId = params['target'] ?? 'default';
    }

    final monitor = MonitorService();
    monitor.init();

    if (widget.ticketId != null || widget.groupId != null && widget.secret != null) {
      _currentId = widget.ticketId?.toString();
      _currentGroupId = widget.groupId;
      _currentSecret = widget.secret;
    } else {
      final last = monitor.readLastKnown(targetId: targetId);
      _currentId = last.label;
      _currentGroupId = last.groupId;
      _currentSecret = last.secret;
    }

    _subscription = monitor.onUpdate.listen((data) {
      if (!mounted) return;

      // Filter messages intended for this specific monitor
      if (data['targetId'] != targetId) return;

      final label = data['label'] as String?;
      final newGroupId = data['groupId'] as String?;
      final newSecret = data['secret'] as String?;

      setState(() {
        _currentId = label;
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
