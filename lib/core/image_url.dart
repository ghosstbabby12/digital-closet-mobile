import 'constants.dart';

String fullImageUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  return '$apiBaseUrl$path';
}
