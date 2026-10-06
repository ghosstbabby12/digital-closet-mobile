import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/user.dart';
import 'secure_storage_provider.dart';

const _tokenKey = 'auth_token';
const _userIdKey = 'auth_user_id';
const _userEmailKey = 'auth_user_email';

class AuthState {
  final String? token;
  final AppUser? user;
  final bool isRestoring;
  final bool isSubmitting;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.isRestoring = true,
    this.isSubmitting = false,
    this.error,
  });

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    String? token,
    AppUser? user,
    bool? isRestoring,
    bool? isSubmitting,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isRestoring: isRestoring ?? this.isRestoring,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: _tokenKey);
    final userId = await storage.read(key: _userIdKey);
    final email = await storage.read(key: _userEmailKey);

    if (token != null && userId != null && email != null) {
      state = state.copyWith(
        token: token,
        user: AppUser(id: int.parse(userId), email: email),
        isRestoring: false,
      );
    } else {
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<void> _persistSession(String token, AppUser user) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _tokenKey, value: token);
    await storage.write(key: _userIdKey, value: user.id.toString());
    await storage.write(key: _userEmailKey, value: user.email);
  }

  Future<bool> register(String email, String password) =>
      _submit(() => _dio.post('/auth/register', data: {'email': email, 'password': password}));

  Future<bool> login(String email, String password) =>
      _submit(() => _dio.post('/auth/login', data: {'email': email, 'password': password}));

  Dio get _dio => Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ));

  Future<bool> _submit(Future<Response> Function() request) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final response = await request();
      final token = response.data['access_token'] as String;
      final user = AppUser.fromJson(response.data['user'] as Map<String, dynamic>);
      await _persistSession(token, user);
      state = state.copyWith(token: token, user: user, isSubmitting: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSubmitting: false, error: ApiException.fromDioError(e).message);
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.deleteAll();
    state = const AuthState(isRestoring: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));
