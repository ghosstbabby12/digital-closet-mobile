import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:closet_ai/features/profile/data/profile_repository.dart';
import 'package:closet_ai/features/profile/presentation/controllers/profile_controller.dart';

class ProfileActions {
  ProfileActions(this._ref);

  final Ref _ref;

  ProfileRepository get _repository => _ref.read(profileRepositoryProvider);

  /// Saves the details. The token is tied to the email, so the new one is stored for the session.
  Future<void> update({
    required String name,
    required String phone,
    required String email,
    String? currentPassword,
  }) async {
    final (_, token) = await _repository.update(
      name: name,
      phone: phone,
      email: email,
      currentPassword: currentPassword,
    );
    await _ref.read(authProvider.notifier).updateSession(token, email);
    _ref.invalidate(profileProvider);
  }

  Future<void> changePassword({required String current, required String next}) =>
      _repository.changePassword(currentPassword: current, newPassword: next);
}

final profileActionsProvider = Provider<ProfileActions>(ProfileActions.new);
