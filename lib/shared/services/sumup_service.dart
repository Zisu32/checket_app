import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

class SumUpService {
  static final SumUpService _instance = SumUpService._internal();
  factory SumUpService() => _instance;
  SumUpService._internal();

  final _storage = web.window.localStorage;
  static const _stationKey = 'checket_station_name';
  static const _readerIdKey = 'checket_selected_reader_id';

  /// Triggers a payment on the physical SumUp Solo terminal.
  Future<bool> triggerTerminalPayment({
    required int slotId,
    required String secret,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final readerId = getSelectedReaderId();
      
      final response = await supabase.functions.invoke(
        'sumup-terminal-pay',
        body: {
          'action': 'pay',
          'slotId': slotId,
          'secret': secret,
          'readerId': readerId, // Targeted payment
        },
      );

      if (response.status == 200) return true;
      throw response.data['error'] ?? 'Unbekannter Fehler bei SumUp.';
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches all readers and their global assignments.
  Future<Map<String, dynamic>> getTerminalStatus() async {
    final response = await Supabase.instance.client.functions.invoke(
      'sumup-terminal-pay',
      body: {'action': 'list-status'},
    );
    return response.data;
  }

  /// Assigns a reader to a specific station globally.
  Future<void> assignTerminal(String station, String readerId, String readerName) async {
    await Supabase.instance.client.functions.invoke(
      'sumup-terminal-pay',
      body: {
        'action': 'assign',
        'stationName': station,
        'readerId': readerId,
        'readerName': readerName,
      },
    );
    // Also set locally for this tablet
    setLocalStation(station, readerId);
  }

  /// Removes a global assignment.
  Future<void> removeAssignment(String readerId) async {
    await Supabase.instance.client.functions.invoke(
      'sumup-terminal-pay',
      body: {'action': 'remove', 'readerId': readerId},
    );
    if (getSelectedReaderId() == readerId) {
      _storage.removeItem(_readerIdKey);
    }
  }

  // --- Local Persistence (Station Identity) ---

  String? getStationName() => _storage.getItem(_stationKey);
  String? getSelectedReaderId() => _storage.getItem(_readerIdKey);

  void setLocalStation(String name, String readerId) {
    _storage.setItem(_stationKey, name);
    _storage.setItem(_readerIdKey, readerId);
  }
}
