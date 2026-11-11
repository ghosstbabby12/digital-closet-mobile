import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:closet_ai/features/profile/data/profile_repository.dart';
import 'package:closet_ai/features/profile/presentation/controllers/profile_controller.dart';

/// Uploads or removes the profile photo. The state is true while it is busy.
class AvatarController extends StateNotifier<bool> {
  AvatarController(this._ref) : super(false);

  final Ref _ref;

  Future<void> upload(XFile image) => _run(() => _ref.read(profileRepositoryProvider).uploadAvatar(image));

  Future<void> remove() => _run(() => _ref.read(profileRepositoryProvider).deleteAvatar());

  Future<void> _run(Future<void> Function() action) async {
    state = true;
    try {
      await action();
      _ref.invalidate(profileProvider);
    } finally {
      if (mounted) state = false;
    }
  }
}

final avatarControllerProvider = StateNotifierProvider.autoDispose<AvatarController, bool>(AvatarController.new);
