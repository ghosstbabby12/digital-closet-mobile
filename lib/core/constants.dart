import 'dart:io' show Platform;

/// URL pública del backend, pasada al compilar:
/// `flutter run --dart-define=API_URL=https://mi-api.onrender.com`
const String _apiUrlOverride = String.fromEnvironment('API_URL');

/// URL base del backend. Sin API_URL se usa el backend local: el emulador de
/// Android usa 10.0.2.2 para llegar al localhost de la máquina anfitriona;
/// iOS simulator y desktop usan localhost directo.
String get apiBaseUrl {
  if (_apiUrlOverride.isNotEmpty) {
    return _apiUrlOverride;
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}

const List<String> occasionOptions = [
  'casual',
  'trabajo',
  'fiesta',
  'deportivo',
  'formal',
];
