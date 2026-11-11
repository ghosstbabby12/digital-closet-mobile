import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/features/try_on/domain/look.dart';
import 'package:closet_ai/core/network/dio_provider.dart';
import 'package:closet_ai/features/try_on/data/look_json.dart';

class LookRepository {
  final Dio _dio;
  LookRepository(this._dio);

  /// Generates the photo with the garments in wearing order. It can take a while:
  /// the AI draws the image and the server may be waking up.
  Future<Look> generate(List<int> garmentIds) async {
    try {
      final response = await _dio.post(
        '/looks',
        data: {'garment_ids': garmentIds},
        options: Options(receiveTimeout: const Duration(seconds: 150)),
      );
      return LookJson.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Look>> list() async {
    try {
      final response = await _dio.get('/looks');
      return (response.data as List).map((json) => LookJson.fromJson(json as Map<String, dynamic>)).toList();
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
