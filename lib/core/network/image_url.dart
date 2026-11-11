import 'package:closet_ai/core/config/api_config.dart';

String fullImageUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  return '$apiBaseUrl$path';
}
