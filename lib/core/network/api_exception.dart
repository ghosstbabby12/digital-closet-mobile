import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  factory ApiException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String);
    }
    if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        'El servidor está tardando en responder (puede estar despertando). Intenta de nuevo en un momento.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return ApiException('No se pudo conectar con el servidor. Verifica tu conexión.');
    }
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return ApiException('El servidor respondió con un error ($statusCode). Intenta de nuevo.');
    }
    return ApiException('Ocurrió un error inesperado. Intenta de nuevo.');
  }

  @override
  String toString() => message;
}
