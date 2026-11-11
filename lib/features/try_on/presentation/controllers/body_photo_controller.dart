import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:closet_ai/features/try_on/data/body_photo_repository.dart';

/// URL of the user's cutout photo, or null if they have not uploaded one yet.
class BodyPhotoNotifier extends StateNotifier<AsyncValue<String?>> {
  final BodyPhotoRepository _repository;

  BodyPhotoNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.current);
  }

  /// On failure the previous photo is kept and the screen shows the error.
  Future<void> upload(XFile image) async {
    final url = await _repository.upload(image);
    state = AsyncValue.data(url);
  }

  Future<void> delete() async {
    await _repository.delete();
    state = const AsyncValue.data(null);
  }
}

// autoDispose: discarded on sign-out, so nobody else sees the photo.
final bodyPhotoProvider = StateNotifierProvider.autoDispose<BodyPhotoNotifier, AsyncValue<String?>>((ref) {
  return BodyPhotoNotifier(ref.read(bodyPhotoRepositoryProvider));
});
