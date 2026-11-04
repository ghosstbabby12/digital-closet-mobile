import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Se envían los bytes (no la ruta) para que funcione también en web.
Future<MultipartFile> multipartFromImage(XFile image) async {
  return MultipartFile.fromBytes(
    await image.readAsBytes(),
    filename: image.name,
    contentType: image.mimeType != null ? DioMediaType.parse(image.mimeType!) : null,
  );
}
