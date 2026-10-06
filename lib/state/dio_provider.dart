import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'auth_provider.dart';

/// Cliente Dio autenticado: adjunta el token JWT vigente a cada petición.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, connectTimeout: const Duration(seconds: 10)));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Token vencido o firmado con otra clave: se cierra la sesión y el
        // router redirige al login.
        if (error.response?.statusCode == 401 && ref.read(authProvider).token != null) {
          ref.read(authProvider.notifier).logout();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
