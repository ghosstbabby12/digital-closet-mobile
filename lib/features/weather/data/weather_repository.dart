import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/features/weather/domain/weather.dart';
import 'package:closet_ai/core/network/dio_provider.dart';
import 'package:closet_ai/features/weather/data/weather_json.dart';

class WeatherRepository {
  final Dio _dio;
  WeatherRepository(this._dio);

  Future<Weather> current({required double lat, required double lon}) async {
    try {
      final response = await _dio.get('/weather', queryParameters: {'lat': lat, 'lon': lon});
      return WeatherJson.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<City>> searchCities(String query) async {
    try {
      final response = await _dio.get('/weather/cities', queryParameters: {'q': query});
      return (response.data as List).map((json) => CityJson.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(ref.read(dioProvider));
});
