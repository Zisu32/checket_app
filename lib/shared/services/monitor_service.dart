import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class MonitorService {
  static final MonitorService _instance = MonitorService._internal();
  factory MonitorService() => _instance;
  MonitorService._internal();

  final _channel = web.BroadcastChannel('checket_monitor_sync');
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  void init() {
    _channel.onmessage = (web.MessageEvent event) {
      final data = event.data;
      if (data != null) {
        // Use dartify to convert JS object back to Dart Map
        final dartData = data.dartify();
        if (dartData is Map) {
          _controller.add(Map<String, dynamic>.from(dartData));
        }
      }
    }.toJS;
  }

  void updateMonitor(int id, String secret) {
    // Use jsify to convert Dart Map to JS object
    final msg = {
      'id': id,
      'secret': secret,
    }.jsify();
    
    _channel.postMessage(msg);
  }

  Stream<Map<String, dynamic>> get onUpdate => _controller.stream;

  void dispose() {
    _channel.close();
    _controller.close();
  }
}
