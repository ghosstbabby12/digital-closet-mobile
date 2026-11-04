import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/body_photo_repository.dart';

/// URL de la foto recortada del usuario, o null si aún no ha subido una.
class BodyPhotoNotifier extends StateNotifier<AsyncValue<String?>> {
  final BodyPhotoRepository _repository;

  BodyPhotoNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.current);
  }

  /// Si falla, conserva la foto anterior y deja que la pantalla muestre el error.
  Future<void> upload(XFile image) async {
    final url = await _repository.upload(image);
    state = AsyncValue.data(url);
  }

  Future<void> delete() async {
    await _repository.delete();
    state = const AsyncValue.data(null);
  }
}

// autoDispose: al cerrar sesión se descarta, para que nadie más vea la foto.
final bodyPhotoProvider =
    StateNotifierProvider.autoDispose<BodyPhotoNotifier, AsyncValue<String?>>((ref) {
  return BodyPhotoNotifier(ref.read(bodyPhotoRepositoryProvider));
});
