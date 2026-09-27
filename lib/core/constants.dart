import 'dart:io' show Platform;

/// URL base del backend. El emulador de Android usa 10.0.2.2 para llegar al
/// localhost de la máquina anfitriona; iOS simulator y desktop/web usan
/// localhost directo. En producción, reemplazar por la URL pública del API.
String get apiBaseUrl {
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
