import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class PlatformHints {
  static String get _ua => web.window.navigator.userAgent;

  static bool get isIOS =>
      RegExp(r'iPad|iPhone|iPod').hasMatch(_ua) ||
          (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

  static bool get isAndroid => _ua.contains('Android');

  static bool get isSafari {
    try {
      final nav = web.window.navigator as JSObject;
      return nav['standalone'] != null;
    } catch (_) {
      return false;
    }
  }

  static bool get isStandalone {
    try {
      return web.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }

  static bool shouldShowInstallHint() {
    if (isStandalone) return false;
    final dismissed = web.window.localStorage.getItem('install_hint_dismissed');
    if (dismissed == 'true') return false;

    if (isIOS) {
      return isSafari;
    }
    if (isAndroid) {
      return true;
    }
    return false;
  }

  static void dismissInstallHint() {
    web.window.localStorage.setItem('install_hint_dismissed', 'true');
  }
}