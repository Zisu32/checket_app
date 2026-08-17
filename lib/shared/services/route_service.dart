import 'package:web/web.dart' as web;

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  ({int? id, String? secret, String? tenant}) parseCustomerParams() {
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
    String tenant = params['tenant'] ?? '';

    final storage = web.window.localStorage;

    // Persist or recover from localStorage for PWA support
    if (ticketIdStr.isNotEmpty && secret.isNotEmpty) {
      storage.setItem('last_ticket_id', ticketIdStr);
      storage.setItem('last_ticket_secret', secret);
      if (tenant.isNotEmpty) storage.setItem('last_tenant', tenant);
    } else {
      ticketIdStr = storage.getItem('last_ticket_id') ?? '';
      secret = storage.getItem('last_ticket_secret') ?? '';
      tenant = storage.getItem('last_tenant') ?? '';
    }

    return (
      id: int.tryParse(ticketIdStr),
      secret: secret.isNotEmpty ? secret : null,
      tenant: tenant.isNotEmpty ? tenant : null,
    );
  }

  /// Parse monitor parameters from a Flutter route name.
  /// Returns a record with optional params and a flag if the route is valid.
  ({int? id, String? secret, bool isQrRoute}) parseStaffParams(String? routeName) {
    if (routeName == null) return (id: null, secret: null, isQrRoute: false);

    // Standardize route name to ensure it starts with / and contains qr
    final path = routeName.startsWith('/') ? routeName : '/$routeName';
    final isQr = path.contains('/qr');

    if (!isQr) {
      return (id: null, secret: null, isQrRoute: false);
    }

    // Extract query parameters if present (for backward compatibility or direct links)
    final uri = Uri.parse(path);
    final idStr = uri.queryParameters['id'] ?? '';
    final secret = uri.queryParameters['secret'];

    return (
      id: int.tryParse(idStr),
      secret: secret,
      isQrRoute: true,
    );
  }
}
