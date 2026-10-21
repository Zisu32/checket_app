import 'package:web/web.dart' as web;

class PlatformHintsService {
  static String get _ua => web.window.navigator.userAgent;

  static bool get isIOS =>
      RegExp(r'iPad|iPhone|iPod').hasMatch(_ua) ||
          (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

  static bool get isAndroid => _ua.contains('Android');

  /// Prueft, ob der Nutzer ein iOS-Geraet nutzt, aber nicht im nativen Safari ist (z.B. Firefox "FxiOS", Chrome "CriOS")
  static bool get isNonSafariIOS {
    if (!isIOS) return false;
    final ua = _ua;
    return ua.contains('FxiOS') ||
        ua.contains('CriOS') ||
        ua.contains('EdgiOS');
  }
}