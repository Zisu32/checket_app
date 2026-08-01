import 'package:web/web.dart' as web;

class PlatformHints {
  static String get _ua => web.window.navigator.userAgent;

  static bool get isIOS =>
      RegExp(r'iPad|iPhone|iPod').hasMatch(_ua) ||
          (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

  static bool get isAndroid => _ua.contains('Android');

  static bool get isStandalone {
    try {
      return web.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }

  /// Banner zeigen, wenn mobiles Gerät (iOS oder Android) und noch nicht
  /// als Standalone-App installiert, und nicht dauerhaft weggewischt.
  static bool shouldShowInstallHint() {
    if (!(isIOS || isAndroid) || isStandalone) return false;
    final dismissed = web.window.localStorage.getItem('install_hint_dismissed');
    return dismissed != 'true';
  }

  static void dismissInstallHint() {
    web.window.localStorage.setItem('install_hint_dismissed', 'true');
  }
}