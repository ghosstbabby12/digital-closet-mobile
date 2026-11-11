import 'package:closet_ai/features/settings/presentation/controllers/theme_controller.dart';
import 'package:closet_ai/features/settings/presentation/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:closet_ai/core/storage/preferences_provider.dart';

void main() {
  Future<SharedPreferences> preferences(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('uses the system theme when nothing is saved', () async {
    final notifier = ThemeModeNotifier(await preferences({}));
    expect(notifier.state, ThemeMode.system);
  });

  test('restores the saved theme when the app reopens', () async {
    final prefs = await preferences({});
    ThemeModeNotifier(prefs).setMode(ThemeMode.dark);
    expect(ThemeModeNotifier(prefs).state, ThemeMode.dark);
  });

  test('an unknown saved value falls back to the system theme', () async {
    final notifier = ThemeModeNotifier(await preferences({'theme_mode': 'rosa'}));
    expect(notifier.state, ThemeMode.system);
  });

  testWidgets('choosing Oscuro in settings changes and saves the theme', (tester) async {
    final prefs = await preferences({'theme_mode': 'light'});
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(onPressed: () => showSettingsSheet(context), child: const Text('abrir')),
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
