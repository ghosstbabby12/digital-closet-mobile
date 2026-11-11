import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Sends the bytes (not the path) so it also works on web.
Future<MultipartFile> multipartFromImage(XFile image) async {
  return MultipartFile.fromBytes(
    await image.readAsBytes(),
    filename: image.name,
    contentType: image.mimeType != null ? DioMediaType.parse(image.mimeType!) : null,
  );
}
