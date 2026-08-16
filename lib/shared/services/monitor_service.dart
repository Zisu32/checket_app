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

  void updateMonitor(int id, String secret) {
    web.window.localStorage.setItem(_kIdKey, id.toString());
    web.window.localStorage.setItem(_kSecretKey, secret);

    _channel.postMessage({'id': id, 'secret': secret}.jsify());
  }

  ({int? id, String? secret}) readLastKnown() {
    final idStr = web.window.localStorage.getItem(_kIdKey);
    final secret = web.window.localStorage.getItem(_kSecretKey);
    return (id: idStr != null ? int.tryParse(idStr) : null, secret: secret);
  }

  Stream<Map<String, dynamic>> get onUpdate => _controller.stream;

  void dispose() {
    _channel.close();
    _controller.close();
  }
}