import 'package:flutter/foundation.dart';

/// Where the app finds the back-end services.
///
/// Defaults target the Android emulator, where the host machine is `10.0.2.2`
/// (web and desktop builds use `localhost`). Override at build time, e.g. for a
/// physical phone on the same Wi-Fi as your computer:
///
///   flutter run --dart-define=API_HOST=192.168.1.20
class ApiConfig {
  ApiConfig._();

  static const String _hostOverride = String.fromEnvironment('API_HOST');
  static const String _hydrationUrlOverride =
      String.fromEnvironment('HYDRATION_API_URL');
  static const String _aiUrlOverride = String.fromEnvironment('AI_API_URL');

  /// The app has no real authentication yet; this user is created by the
  /// water-intake service on startup.
  static const String userId = String.fromEnvironment('USER_ID',
      defaultValue: '66036b08fe2d6569e5efbb5c');

  static const Duration timeout = Duration(seconds: 15);

  /// LLM answers can take a while on shared inference providers.
  static const Duration chatTimeout = Duration(seconds: 90);

  static String get host {
    if (_hostOverride.isNotEmpty) return _hostOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get hydrationBaseUrl => _hydrationUrlOverride.isNotEmpty
      ? _hydrationUrlOverride
      : 'http://$host:8082';

  static String get aiBaseUrl =>
      _aiUrlOverride.isNotEmpty ? _aiUrlOverride : 'http://$host:8081';
}
