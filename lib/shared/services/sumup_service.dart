import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

class SumUpService {
  static final SumUpService _instance = SumUpService._internal();
  factory SumUpService() => _instance;
  SumUpService._internal();

  final _storage = web.window.localStorage;
  static const _stationKey = 'checket_station_name';
  static const _readerIdKey = 'checket_selected_reader_id';

  // Triggers a payment on the physical SumUp Solo terminal and returns the SumUp checkoutId if successful.
  Future<String?> triggerTerminalPayment({
    required int slotCount,
    List<int>? slotIds,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final readerId = getSelectedReaderId();
      
      final response = await supabase.functions.invoke(
        'sumup-terminal-pay',
        body: {
          'action': 'pay',
          'slotCount': slotCount,
          'slotIds': slotIds,
          'readerId': readerId,
        },
      );

      if (response.status == 200) {
        return response.data['checkoutId'] as String?;
      } else {
        final errorMsg = response.data is Map ? response.data['error'] : 'Fehler beim Aufruf der Zahlungsfunktion.';
        throw errorMsg ?? 'Unbekannter Fehler bei SumUp.';
      }
    } catch (e) {
      rethrow;
    }
  }

  // Checks the current status of a specific checkout.
  Future<String> checkPaymentStatus(String checkoutId) async {
    final response = await Supabase.instance.client.functions.invoke(
      'sumup-terminal-pay',
      body: {
        'action': 'check-status',
        'checkoutId': checkoutId,
      },
    );
    return (response.data['status'] as String?)?.toUpperCase() ?? 'UNKNOWN';
  }

  // Fetches all readers and their global assignments.
  Future<Map<String, dynamic>> getTerminalStatus() async {
    final response = await Supabase.instance.client.functions.invoke(
      'sumup-terminal-pay',
      body: {'action': 'list-status'},
    );
    return response.data;
  }

  // Assigns a reader to a specific station globally.
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
    setLocalStation(station, readerId);
  }

  // Removes a global assignment.
  Future<void> removeAssignment(String readerId) async {
    await Supabase.instance.client.functions.invoke(
      'sumup-terminal-pay',
      body: {'action': 'remove', 'readerId': readerId},
    );
    if (getSelectedReaderId() == readerId) {
      _storage.removeItem(_readerIdKey);
    }
  }

  // Local Persistence of Station Identity
  String? getStationName() => _storage.getItem(_stationKey);
  String? getSelectedReaderId() => _storage.getItem(_readerIdKey);

  void setLocalStation(String name, String readerId) {
    _storage.setItem(_stationKey, name);
    _storage.setItem(_readerIdKey, readerId);
  }
}
