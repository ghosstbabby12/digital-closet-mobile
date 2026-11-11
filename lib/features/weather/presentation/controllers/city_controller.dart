import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/storage/preferences_provider.dart';
import 'package:closet_ai/features/weather/data/city_storage.dart';
import 'package:closet_ai/features/weather/domain/weather.dart';

/// The city chosen for the weather; null until one is chosen.
class SelectedCityNotifier extends StateNotifier<City?> {
  final CityStorage _storage;

  SelectedCityNotifier(this._storage) : super(_storage.read());

  void select(City city) {
    state = city;
    _storage.save(city);
  }
}

final selectedCityProvider = StateNotifierProvider<SelectedCityNotifier, City?>((ref) {
  return SelectedCityNotifier(CityStorage(ref.watch(sharedPreferencesProvider)));
});
