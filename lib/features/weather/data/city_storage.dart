import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:closet_ai/features/weather/data/weather_json.dart';
import 'package:closet_ai/features/weather/domain/weather.dart';

/// Remembers the chosen city between app launches.
class CityStorage {
  static const _key = 'weather_city';

  final SharedPreferences _preferences;

  CityStorage(this._preferences);

  City? read() {
    final saved = _preferences.getString(_key);
    if (saved == null) return null;
    try {
      return CityJson.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void save(City city) => _preferences.setString(_key, jsonEncode(city.toJson()));
}
