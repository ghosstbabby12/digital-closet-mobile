import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  factory ApiException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String);
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return ApiException('No se pudo conectar con el servidor. Verifica tu conexión.');
    }
    return ApiException('Ocurrió un error inesperado. Intenta de nuevo.');
  }

  @override
  String toString() => message;
}
