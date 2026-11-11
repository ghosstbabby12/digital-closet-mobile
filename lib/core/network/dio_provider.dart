import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/config/api_config.dart';
import 'package:closet_ai/features/auth/presentation/controllers/auth_controller.dart';

/// Authenticated Dio client: attaches the current JWT to every request.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, connectTimeout: apiConnectTimeout, receiveTimeout: apiReceiveTimeout),
  );

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
        // Expired token, or signed with another key: sign out and the
        // router redirects to the login.
        if (error.response?.statusCode == 401 && ref.read(authProvider).token != null) {
          ref.read(authProvider.notifier).logout();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
