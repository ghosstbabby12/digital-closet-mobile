import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/data/garment_repository.dart';
import 'package:closet_ai/features/auth/presentation/controllers/auth_controller.dart';

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
    state = AsyncValue.data([for (final item in state.value ?? <Garment>[]) item.id == updated.id ? updated : item]);
  }

  /// Returns the garment with its cutout, creating it only if it does not exist yet.
  Future<Garment> ensureCutout(Garment garment) async {
    if (garment.cutoutUrl != null) return garment;
    final updated = await _repository.createCutout(garment.id);
    state = AsyncValue.data([for (final item in state.value ?? <Garment>[]) item.id == updated.id ? updated : item]);
    return updated;
  }

  Future<void> removeGarment(int id) async {
    await _repository.delete(id);
    state = AsyncValue.data((state.value ?? []).where((g) => g.id != id).toList());
  }
}

final closetProvider = StateNotifierProvider<ClosetNotifier, AsyncValue<List<Garment>>>((ref) {
  // Reloads when the user changes, so the previous session's closet is never shown.
  ref.watch(authProvider.select((auth) => auth.user?.id));
  return ClosetNotifier(ref.read(garmentRepositoryProvider));
});
