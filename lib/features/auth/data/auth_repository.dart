import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/config/api_config.dart';
import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/features/auth/data/app_user_json.dart';
import 'package:closet_ai/features/auth/domain/session.dart';

/// Sign-up and sign-in. Uses its own client because there is no token yet.
class AuthRepository {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, connectTimeout: apiConnectTimeout, receiveTimeout: apiReceiveTimeout),
  );

  Future<Session> register(String email, String password) => _authenticate('/auth/register', email, password);

  Future<Session> login(String email, String password) => _authenticate('/auth/login', email, password);

  Future<Session> _authenticate(String path, String email, String password) async {
    try {
      final response = await _dio.post(path, data: {'email': email, 'password': password});
      final data = response.data as Map<String, dynamic>;
      return Session(
        token: data['access_token'] as String,
        user: AppUserJson.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
