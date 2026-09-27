import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/garment.dart';
import '../state/dio_provider.dart';

class GarmentRepository {
  final Dio _dio;
  GarmentRepository(this._dio);

  Future<List<Garment>> list() async {
    try {
      final response = await _dio.get('/garments');
      return (response.data as List)
          .map((json) => Garment.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Garment> create({
    required GarmentCategory category,
    required String color,
    required WarmthLevel warmth,
    required String name,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'category': category.name,
        'color': color,
        'warmth': warmth.name,
        'name': name,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.uri.pathSegments.last,
        ),
      });
      final response = await _dio.post('/garments', data: formData);
      return Garment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/garments/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final garmentRepositoryProvider = Provider<GarmentRepository>((ref) {
  return GarmentRepository(ref.read(dioProvider));
});
