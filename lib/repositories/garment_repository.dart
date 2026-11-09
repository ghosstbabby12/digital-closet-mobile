import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../core/image_upload.dart';
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
    required XFile image,
  }) async {
    try {
      final formData = FormData.fromMap({
        'category': category.name,
        'color': color,
        'warmth': warmth.name,
        'name': name,
        'image': await multipartFromImage(image),
      });
      final response = await _dio.post('/garments', data: formData);
      return Garment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Cambia nombre, color, categoría y nivel de abrigo.
  Future<Garment> update(
    int id, {
    required String name,
    required String color,
    required GarmentCategory category,
    required WarmthLevel warmth,
  }) async {
    try {
      final response = await _dio.patch('/garments/$id', data: {
        'name': name,
        'color': color,
        'category': category.name,
        'warmth': warmth.name,
      });
      return Garment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Propone los datos de una prenda a partir de su foto, sin guardar nada.
  Future<GarmentSuggestion> suggest(XFile image) async {
    try {
      final formData = FormData.fromMap({'image': await multipartFromImage(image)});
      final response = await _dio.post('/garments/suggest', data: formData);
      return GarmentSuggestion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Genera (o recupera) la versión de la prenda con fondo transparente.
  Future<Garment> createCutout(int id) async {
    try {
      final response = await _dio.post('/garments/$id/cutout');
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
