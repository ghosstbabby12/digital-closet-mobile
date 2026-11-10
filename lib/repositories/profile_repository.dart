import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/profile.dart';
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
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(dioProvider));
});

// autoDispose: se vuelve a pedir cada vez que se abre el perfil, con los totales al día.
final profileProvider = FutureProvider.autoDispose<Profile>((ref) {
  return ref.read(profileRepositoryProvider).fetch();
});
