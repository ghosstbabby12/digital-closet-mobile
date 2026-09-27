import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/outfit.dart';
import '../repositories/outfit_repository.dart';

class OutfitGenerateNotifier extends StateNotifier<AsyncValue<Outfit?>> {
  final OutfitRepository _repository;

  OutfitGenerateNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> generate({required String occasion, required double lat, required double lon}) async {
    state = const AsyncValue.loading();
    try {
      final outfit = await _repository.generate(occasion: occasion, lat: lat, lon: lon);
      state = AsyncValue.data(outfit);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final outfitGenerateProvider =
    StateNotifierProvider<OutfitGenerateNotifier, AsyncValue<Outfit?>>((ref) {
  return OutfitGenerateNotifier(ref.read(outfitRepositoryProvider));
});

final outfitHistoryProvider = FutureProvider.autoDispose<List<Outfit>>((ref) async {
  final repository = ref.read(outfitRepositoryProvider);
  return repository.history();
});
