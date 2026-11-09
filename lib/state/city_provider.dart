import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';
import 'theme_provider.dart';

const _cityKey = 'weather_city';

/// Ciudad elegida para el clima; null mientras no se haya elegido ninguna.
class SelectedCityNotifier extends StateNotifier<City?> {
  final SharedPreferences _preferences;

  SelectedCityNotifier(this._preferences) : super(_load(_preferences));

  static City? _load(SharedPreferences preferences) {
    final saved = preferences.getString(_cityKey);
    if (saved == null) return null;
    try {
      return City.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void select(City city) {
    state = city;
    _preferences.setString(_cityKey, jsonEncode(city.toJson()));
  }
}

final selectedCityProvider = StateNotifierProvider<SelectedCityNotifier, City?>((ref) {
  return SelectedCityNotifier(ref.watch(sharedPreferencesProvider));
});
