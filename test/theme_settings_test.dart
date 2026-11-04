import 'package:closet_ai/state/theme_provider.dart';
import 'package:closet_ai/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> preferences(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('usa el tema del sistema si no hay nada guardado', () async {
    final notifier = ThemeModeNotifier(await preferences({}));
    expect(notifier.state, ThemeMode.system);
  });

  test('recupera el tema guardado al volver a abrir la app', () async {
    final prefs = await preferences({});
    ThemeModeNotifier(prefs).setMode(ThemeMode.dark);
    expect(ThemeModeNotifier(prefs).state, ThemeMode.dark);
  });

  test('un valor guardado desconocido vuelve al tema del sistema', () async {
    final notifier = ThemeModeNotifier(await preferences({'theme_mode': 'rosa'}));
    expect(notifier.state, ThemeMode.system);
  });

  testWidgets('elegir Oscuro en Ajustes cambia y guarda el tema', (tester) async {
    final prefs = await preferences({'theme_mode': 'light'});
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSettingsSheet(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
  }, semanticsEnabled: false);
}
