import 'dart:async';
import 'package:web/web.dart' as web;

class MonitorService {
  static final MonitorService _instance = MonitorService._internal();
  factory MonitorService() => _instance;
  MonitorService._internal();

  final _channel = web.BroadcastChannel('checket_monitor_sync');
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  void init() {
    _channel.onmessage = (web.MessageEvent event) {
      final data = event.data as Map;
      _controller.add(Map<String, dynamic>.from(data));
    }.toJS;
  }

  void updateMonitor(int id, String secret) {
    _channel.postMessage({
      'id': id,
      'secret': secret,
    }.toJS);
  }

  Stream<Map<String, dynamic>> get onUpdate => _controller.stream;

  void dispose() {
    _channel.close();
    _controller.close();
  }
}
