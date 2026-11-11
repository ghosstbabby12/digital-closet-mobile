import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/core/network/image_upload.dart';
import 'package:closet_ai/core/network/dio_provider.dart';

class BodyPhotoRepository {
  final Dio _dio;
  BodyPhotoRepository(this._dio);

  Future<String?> current() async {
    try {
      final response = await _dio.get('/me/body-photo');
      return response.data['image_url'] as String?;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> upload(XFile image) async {
    try {
      final formData = FormData.fromMap({'image': await multipartFromImage(image)});
      final response = await _dio.put('/me/body-photo', data: formData);
      return response.data['image_url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete() async {
    try {
      await _dio.delete('/me/body-photo');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final bodyPhotoRepositoryProvider = Provider<BodyPhotoRepository>((ref) {
  return BodyPhotoRepository(ref.read(dioProvider));
});
