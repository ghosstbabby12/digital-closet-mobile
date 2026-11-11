import 'package:flutter/foundation.dart';

/// Public backend URL, set at build time:
/// `flutter run --dart-define=API_URL=https://my-api.onrender.com`
const String _apiUrlOverride = String.fromEnvironment('API_URL');

/// Backend base URL. Without API_URL the local backend is used: the Android
/// emulator reaches the host's localhost through 10.0.2.2; web, the iOS
/// simulator and desktop use localhost directly.
String get apiBaseUrl {
  if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000';
}

/// Render's free plan sleeps the server after 15 idle minutes and takes up to
/// ~50 s to wake up, so the timeouts are generous.
const Duration apiConnectTimeout = Duration(seconds: 60);
const Duration apiReceiveTimeout = Duration(seconds: 60);
