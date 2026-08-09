import 'package:web/web.dart' as web;

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

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

  ({int? id, String? secret}) parseStaffParams(String? routeName) {
    if (routeName == null) return (id: null, secret: null);

    // Standardize route name to ensure it starts with / and contains qr
    final path = routeName.startsWith('/') ? routeName : '/$routeName';
    if (!path.contains('/qr')) {
      return (id: null, secret: null);
    }

    // Extract query parameters from the path (e.g., /qr?id=12&secret=ABC)
    final uri = Uri.parse(path);
    final idStr = uri.queryParameters['id'] ?? '';
    final secret = uri.queryParameters['secret'];

    return (
      id: int.tryParse(idStr),
      secret: secret,
    );
  }
}
