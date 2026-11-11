import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:closet_ai/core/network/dio_provider.dart';
import 'package:closet_ai/features/outfits/data/outfit_json.dart';

class OutfitRepository {
  final Dio _dio;
  OutfitRepository(this._dio);

  Future<Outfit> generate({
    required String occasion,
    required double lat,
    required double lon,
    String? eventTitle,
    DateTime? eventDate,
  }) async {
    try {
      final response = await _dio.post(
        '/outfits/generate',
        data: {
          'occasion': occasion,
          'lat': lat,
          'lon': lon,
          if (eventTitle != null && eventDate != null) ...{
            'event_title': eventTitle,
            'event_date': DateFormat('yyyy-MM-dd').format(eventDate),
          },
        },
      );
      return OutfitJson.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/outfits/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Outfit>> history() async {
    try {
      final response = await _dio.get('/outfits');
      return (response.data as List).map((json) => OutfitJson.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return OutfitRepository(ref.read(dioProvider));
});
