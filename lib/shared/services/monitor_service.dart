import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class MonitorService {
  static final MonitorService _instance = MonitorService._internal();
  factory MonitorService() => _instance;
  MonitorService._internal();

  final _channel = web.BroadcastChannel('checket_monitor_sync');
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _listening = false;

  void init() {
    if (_listening) return;
    _listening = true;
    _channel.onmessage = (web.MessageEvent event) {
      final dartData = event.data?.dartify();
      if (dartData is Map) {
        _controller.add(Map<String, dynamic>.from(dartData));
      }
    }.toJS;
  }

  void updateMonitor({
    String? label,
    String? groupId,
    required String secret,
    String targetId = 'default',
  }) {
    final prefix = 'monitor_${targetId}_';
    
    if (label != null) {
      web.window.localStorage.setItem('${prefix}last_label', label);
    } else {
      web.window.localStorage.removeItem('${prefix}last_label');
    }

    if (groupId != null) {
      web.window.localStorage.setItem('${prefix}last_group_id', groupId);
    } else {
      web.window.localStorage.removeItem('${prefix}last_group_id');
    }

    web.window.localStorage.setItem('${prefix}last_secret', secret);

    _channel.postMessage({
      'targetId': targetId,
      'label': label, 
      'groupId': groupId,
      'secret': secret
    }.jsify());
  }

  ({String? label, String? groupId, String? secret}) readLastKnown({String targetId = 'default'}) {
    final prefix = 'monitor_${targetId}_';
    final label = web.window.localStorage.getItem('${prefix}last_label');
    final groupId = web.window.localStorage.getItem('${prefix}last_group_id');
    final secret = web.window.localStorage.getItem('${prefix}last_secret');
    return (
      label: label, 
      groupId: groupId,
      secret: secret
    );
  }

  Stream<Map<String, dynamic>> get onUpdate => _controller.stream;

  void dispose() {
    _channel.close();
    _controller.close();
  }
}
