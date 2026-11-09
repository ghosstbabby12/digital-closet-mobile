import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/weather.dart';
import '../state/dio_provider.dart';

class WeatherRepository {
  final Dio _dio;
  WeatherRepository(this._dio);

  Future<Weather> current({required double lat, required double lon}) async {
    try {
      final response = await _dio.get('/weather', queryParameters: {'lat': lat, 'lon': lon});
      return Weather.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<City>> searchCities(String query) async {
    try {
      final response = await _dio.get('/weather/cities', queryParameters: {'q': query});
      return (response.data as List).map((json) => City.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(ref.read(dioProvider));
});
