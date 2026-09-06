import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/app_theme.dart';
import '../../shared/services/monitor_service.dart';
import '../../shared/services/sync_service.dart';
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
  bool _isSuccess = false;
  late StreamSubscription _subscription;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    web.document.title = 'Checket QR';
    _initMonitor();
  }

  void _initMonitor() {
    final fullUrl = web.window.location.href;
    final uri = Uri.parse(fullUrl);
    
    String targetId = 'default';
    final windowName = web.window.name;
    if (windowName.startsWith('checket_monitor_')) {
      targetId = windowName.replaceFirst('checket_monitor_', '');
    } else {
      Map<String, String> params = Map.from(uri.queryParameters);
      if (uri.hasFragment) {
        final fragment = uri.fragment.contains('?') ? uri.fragment.split('?').last : '';
        if (fragment.isNotEmpty) params.addAll(Uri.splitQueryString(fragment));
      }
      targetId = params['target'] ?? 'default';
    }

    final monitor = MonitorService();
    monitor.init();

    if (widget.ticketId != null || (widget.groupId != null && widget.secret != null)) {
      _currentId = widget.ticketId?.toString();
      _currentGroupId = widget.groupId;
      _currentSecret = widget.secret;
      _listenForStatus();
    } else {
      final last = monitor.readLastKnown(targetId: targetId);
      _currentId = last.label;
      _currentGroupId = last.groupId;
      _currentSecret = last.secret;
      if (_currentSecret != null) {
        _listenForStatus();
      }
    }

    _subscription = monitor.onUpdate.listen((data) {
      if (!mounted) return;
      if (data['targetId'] != targetId) return;

      final label = data['label'] as String?;
      final newGroupId = data['groupId'] as String?;
      final newSecret = data['secret'] as String?;

      setState(() {
        _currentId = label;
        _currentGroupId = newGroupId;
        _currentSecret = newSecret;
        _isSuccess = false;
      });

      if (newSecret != null) {
        _listenForStatus();
      }
    });
  }

  void _listenForStatus() {
    _statusSubscription?.cancel();
    if (_currentId == null || _currentSecret == null) return;
    
    final sync = SyncService();
    final firstIdStr = _currentId!.split(',').first.trim();
    final firstId = int.tryParse(firstIdStr) ?? 0;
    
    if (firstId == 0) return;

    _statusSubscription = sync.watchTicket(firstId, _currentSecret!).listen((slot) {
      if (!mounted) return;
      if (slot != null && slot.status == 'active' && !_isSuccess) {
        setState(() {
          _isSuccess = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _statusSubscription?.cancel();
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
          title: SvgPicture.asset('assets/images/full-icon.svg', height: 28),
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
              isSuccess: _isSuccess,
            ),
          ),
        ),
      ),
    );
  }
}
