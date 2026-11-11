import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:closet_ai/core/storage/preferences_provider.dart';

const _themeModeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _preferences;

  ThemeModeNotifier(this._preferences)
    : super(
        ThemeMode.values.firstWhere(
          (mode) => mode.name == _preferences.getString(_themeModeKey),
          orElse: () => ThemeMode.system,
        ),
      );

  void setMode(ThemeMode mode) {
    state = mode;
    _preferences.setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});
