import 'package:supabase_flutter/supabase_flutter.dart';

class SumUpService {
  static final SumUpService _instance = SumUpService._internal();
  factory SumUpService() => _instance;
  SumUpService._internal();

  /// Triggers a payment on the physical SumUp Solo terminal via Supabase Edge Function.
  Future<bool> triggerTerminalPayment({
    required int slotId,
    required String secret,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Call the Edge Function
      final response = await supabase.functions.invoke(
        'sumup-terminal-pay',
        body: {
          'slotId': slotId,
          'secret': secret,
        },
      );

      if (response.status == 200) {
        return true;
      } else {
        // Extract error message from the response data
        final errorMsg = response.data is Map ? response.data['error'] : 'Fehler beim Aufruf der Zahlungsfunktion.';
        throw errorMsg ?? 'Unbekannter Fehler bei SumUp.';
      }
    } catch (e) {
      rethrow;
    }
  }
}
