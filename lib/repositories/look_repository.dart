import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/look.dart';
import '../state/dio_provider.dart';

class LookRepository {
  final Dio _dio;
  LookRepository(this._dio);

  /// Genera la foto con las prendas en orden de vestir. Puede tardar bastante:
  /// la IA dibuja la imagen y el servidor puede estar despertando.
  Future<Look> generate(List<int> garmentIds) async {
    try {
      final response = await _dio.post(
        '/looks',
        data: {'garment_ids': garmentIds},
        options: Options(receiveTimeout: const Duration(seconds: 150)),
      );
      return Look.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Look>> list() async {
    try {
      final response = await _dio.get('/looks');
      return (response.data as List).map((json) => Look.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/looks/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final lookRepositoryProvider = Provider<LookRepository>((ref) {
  return LookRepository(ref.read(dioProvider));
});

final looksProvider = FutureProvider.autoDispose<List<Look>>((ref) {
  return ref.read(lookRepositoryProvider).list();
});
