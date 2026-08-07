import 'package:web/web.dart' as web;

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  /// Robustly parse customer parameters from the URL or localStorage.
  /// Used in main_customer.dart to identify the guest's ticket.
  ({int? id, String? secret}) parseCustomerParams() {
    final fullUrl = web.window.location.href;
    final uri = Uri.parse(fullUrl);
    
    Map<String, String> params = Map.from(uri.queryParameters);
    
    // Support hash-based query parameters as well
    if (uri.hasFragment) {
      final fragment = uri.fragment.contains('?') ? uri.fragment.split('?').last : '';
      if (fragment.isNotEmpty) {
        params.addAll(Uri.splitQueryString(fragment));
      }
    }

    String ticketIdStr = params['id'] ?? '';
    String secret = params['secret'] ?? '';

    final storage = web.window.localStorage;

    // Persist or recover from localStorage for PWA support
    if (ticketIdStr.isNotEmpty && secret.isNotEmpty) {
      storage.setItem('last_ticket_id', ticketIdStr);
      storage.setItem('last_ticket_secret', secret);
    } else {
      ticketIdStr = storage.getItem('last_ticket_id') ?? '';
      secret = storage.getItem('last_ticket_secret') ?? '';
    }

    return (
      id: int.tryParse(ticketIdStr),
      secret: secret.isNotEmpty ? secret : null,
    );
  }

  /// Parse monitor parameters from a Flutter route name.
  /// Used in main_staff.dart to show the correct QR code on the monitor.
  ({int? id, String? secret}) parseStaffParams(String? routeName) {
    if (routeName == null || !routeName.contains('/qr')) {
      return (id: null, secret: null);
    }

    final uri = Uri.parse(routeName.startsWith('/') ? routeName : '/$routeName');
    final idStr = uri.queryParameters['id'] ?? '';
    final secret = uri.queryParameters['secret'];

    return (
      id: int.tryParse(idStr),
      secret: secret,
    );
  }
}
