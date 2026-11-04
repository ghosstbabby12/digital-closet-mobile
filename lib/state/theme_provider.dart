import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

/// Se reemplaza en `main` con la instancia ya cargada, para que la app abra
/// con el tema elegido sin un parpadeo del tema por defecto.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider debe sobrescribirse en main');
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _preferences;

  ThemeModeNotifier(this._preferences)
      : super(ThemeMode.values.firstWhere(
          (mode) => mode.name == _preferences.getString(_themeModeKey),
          orElse: () => ThemeMode.system,
        ));

  void setMode(ThemeMode mode) {
    state = mode;
    _preferences.setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});
