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

  static const _kIdKey = 'monitor_last_id';
  static const _kGroupIdKey = 'monitor_last_group_id';
  static const _kSecretKey = 'monitor_last_secret';

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

  void updateMonitor(int? id, String secret, {String? groupId, String targetId = 'default'}) {
    final prefix = 'monitor_${targetId}_';
    if (id != null) web.window.localStorage.setItem('${prefix}last_id', id.toString());
    if (groupId != null) web.window.localStorage.setItem('${prefix}last_group_id', groupId);
    web.window.localStorage.setItem('${prefix}last_secret', secret);

    _channel.postMessage({
      'targetId': targetId,
      'id': id, 
      'groupId': groupId,
      'secret': secret
    }.jsify());
  }

  ({int? id, String? groupId, String? secret}) readLastKnown({String targetId = 'default'}) {
    final prefix = 'monitor_${targetId}_';
    final idStr = web.window.localStorage.getItem('${prefix}last_id');
    final groupId = web.window.localStorage.getItem('${prefix}last_group_id');
    final secret = web.window.localStorage.getItem('${prefix}last_secret');
    return (
      id: idStr != null ? int.tryParse(idStr) : null, 
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