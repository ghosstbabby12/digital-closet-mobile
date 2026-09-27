import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/garment.dart';
import '../repositories/garment_repository.dart';

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
    required File imageFile,
  }) async {
    final created = await _repository.create(
      category: category,
      color: color,
      warmth: warmth,
      name: name,
      imageFile: imageFile,
    );
    state = AsyncValue.data([created, ...state.value ?? []]);
  }

  Future<void> removeGarment(int id) async {
    await _repository.delete(id);
    state = AsyncValue.data((state.value ?? []).where((g) => g.id != id).toList());
  }
}

final closetProvider = StateNotifierProvider<ClosetNotifier, AsyncValue<List<Garment>>>((ref) {
  return ClosetNotifier(ref.read(garmentRepositoryProvider));
});
