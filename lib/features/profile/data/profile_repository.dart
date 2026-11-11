import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/core/network/image_upload.dart';
import 'package:closet_ai/features/profile/domain/profile.dart';
import 'package:closet_ai/core/network/dio_provider.dart';
import 'package:closet_ai/features/profile/data/profile_json.dart';

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  Future<Profile> fetch() async {
    try {
      final response = await _dio.get('/me');
      return ProfileJson.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Saves name, phone and email. Returns the profile and the new token
  /// (the token is tied to the email). [currentPassword] is only needed when the email changes.
  Future<(Profile, String)> update({
    required String name,
    required String phone,
    required String email,
    String? currentPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/me',
        data: {'name': name, 'phone': phone, 'email': email, 'current_password': ?currentPassword},
      );
      final data = response.data as Map<String, dynamic>;
      return (ProfileJson.fromJson(data), data['access_token'] as String);
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
