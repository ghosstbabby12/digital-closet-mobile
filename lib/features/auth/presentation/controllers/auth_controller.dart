import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/features/auth/data/auth_repository.dart';
import 'package:closet_ai/features/auth/data/session_storage.dart';
import 'package:closet_ai/features/auth/domain/app_user.dart';
import 'package:closet_ai/features/auth/domain/session.dart';

class AuthState {
  final String? token;
  final AppUser? user;
  final bool isRestoring;
  final bool isSubmitting;
  final String? error;

  const AuthState({this.token, this.user, this.isRestoring = true, this.isSubmitting = false, this.error});

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({String? token, AppUser? user, bool? isRestoring, bool? isSubmitting, String? error}) => AuthState(
    token: token ?? this.token,
    user: user ?? this.user,
    isRestoring: isRestoring ?? this.isRestoring,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: error,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _restoreSession();
  }

  SessionStorage get _storage => _ref.read(sessionStorageProvider);
  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  Future<void> _restoreSession() async {
    final session = await _storage.read();
    state = session == null
        ? state.copyWith(isRestoring: false)
        : state.copyWith(token: session.token, user: session.user, isRestoring: false);
  }

  Future<bool> register(String email, String password) => _signIn(() => _repository.register(email, password));

  Future<bool> login(String email, String password) => _signIn(() => _repository.login(email, password));

  Future<bool> _signIn(Future<Session> Function() request) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _start(await request());
      state = state.copyWith(isSubmitting: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    }
  }

  /// After changing the email in the profile: the token is tied to the email,
  /// so the new one returned by the server is stored.
  Future<void> updateSession(String token, String email) => _start(
    Session(
      token: token,
      user: AppUser(id: state.user!.id, email: email),
    ),
  );

  Future<void> _start(Session session) async {
    await _storage.save(session);
    state = state.copyWith(token: session.token, user: session.user);
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState(isRestoring: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
