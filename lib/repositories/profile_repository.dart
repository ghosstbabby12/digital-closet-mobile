import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../core/image_upload.dart';
import '../models/profile.dart';
import '../state/auth_provider.dart';
import '../state/dio_provider.dart';

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  Future<Profile> fetch() async {
    try {
      final response = await _dio.get('/me');
      return Profile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Guarda nombre, teléfono y correo. Devuelve el perfil y el token nuevo
  /// (el token va ligado al correo). [currentPassword] solo hace falta si cambia el correo.
  Future<(Profile, String)> update({
    required String name,
    required String phone,
    required String email,
    String? currentPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/me',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'current_password': ?currentPassword,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (Profile.fromJson(data), data['access_token'] as String);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _dio.put('/me/password', data: {'current_password': currentPassword, 'new_password': newPassword});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> uploadAvatar(XFile image) async {
    try {
      await _dio.put('/me/avatar', data: FormData.fromMap({'image': await multipartFromImage(image)}));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteAvatar() async {
    try {
      await _dio.delete('/me/avatar');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(dioProvider));
});

/// Perfil del usuario. Se descarta al cerrar sesión (y al cambiar de cuenta).
final profileProvider = FutureProvider.autoDispose<Profile>((ref) {
  ref.watch(authProvider.select((auth) => auth.user?.id));
  return ref.read(profileRepositoryProvider).fetch();
});
