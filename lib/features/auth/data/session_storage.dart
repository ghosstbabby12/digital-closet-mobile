import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:closet_ai/core/storage/secure_storage_provider.dart';
import 'package:closet_ai/features/auth/domain/app_user.dart';
import 'package:closet_ai/features/auth/domain/session.dart';

/// Keeps the session in the phone's secure storage so the user stays signed in.
class SessionStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _userEmailKey = 'auth_user_email';

  final FlutterSecureStorage _storage;

  SessionStorage(this._storage);

  Future<Session?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final userId = await _storage.read(key: _userIdKey);
    final email = await _storage.read(key: _userEmailKey);
    if (token == null || userId == null || email == null) return null;
    return Session(
      token: token,
      user: AppUser(id: int.parse(userId), email: email),
    );
  }

  Future<void> save(Session session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userIdKey, value: session.user.id.toString());
    await _storage.write(key: _userEmailKey, value: session.user.email);
  }

  Future<void> clear() => _storage.deleteAll();
}

final sessionStorageProvider = Provider<SessionStorage>((ref) => SessionStorage(ref.read(secureStorageProvider)));
