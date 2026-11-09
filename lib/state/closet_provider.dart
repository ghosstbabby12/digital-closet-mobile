import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/garment.dart';
import '../repositories/garment_repository.dart';
import 'auth_provider.dart';

class ClosetNotifier extends StateNotifier<AsyncValue<List<Garment>>> {
  final GarmentRepository _repository;

  ClosetNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final garments = await _repository.list();
      state = AsyncValue.data(garments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addGarment({
    required GarmentCategory category,
    required String color,
    required WarmthLevel warmth,
    required String name,
    required XFile image,
  }) async {
    final created = await _repository.create(
      category: category,
      color: color,
      warmth: warmth,
      name: name,
      image: image,
    );
    state = AsyncValue.data([created, ...state.value ?? []]);
  }

  Future<void> updateGarment(
    Garment garment, {
    required String name,
    required String color,
    required GarmentCategory category,
    required WarmthLevel warmth,
  }) async {
    final updated = await _repository.update(garment.id, name: name, color: color, category: category, warmth: warmth);
    state = AsyncValue.data([
      for (final item in state.value ?? <Garment>[]) item.id == updated.id ? updated : item,
    ]);
  }

  /// Devuelve la prenda con su recorte, generándolo solo si aún no existe.
  Future<Garment> ensureCutout(Garment garment) async {
    if (garment.cutoutUrl != null) return garment;
    final updated = await _repository.createCutout(garment.id);
    state = AsyncValue.data([
      for (final item in state.value ?? <Garment>[]) item.id == updated.id ? updated : item,
    ]);
    return updated;
  }

  Future<void> removeGarment(int id) async {
    await _repository.delete(id);
    state = AsyncValue.data((state.value ?? []).where((g) => g.id != id).toList());
  }
}

final closetProvider = StateNotifierProvider<ClosetNotifier, AsyncValue<List<Garment>>>((ref) {
  // Se recarga al cambiar de usuario, para no mostrar el clóset de la sesión anterior.
  ref.watch(authProvider.select((auth) => auth.user?.id));
  return ClosetNotifier(ref.read(garmentRepositoryProvider));
});
