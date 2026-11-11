import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:closet_ai/core/theme/app_theme.dart';
import 'package:closet_ai/core/router/app_router.dart';
import 'package:closet_ai/features/settings/presentation/controllers/theme_controller.dart';
import 'package:closet_ai/core/storage/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)], child: const ClosetApp()),
  );
}

class ClosetApp extends ConsumerWidget {
  const ClosetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Curador de Moda IA',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          // On web and desktop the content does not stretch to the full width.
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: child),
            ),
          ),
        );
      },
    );
  }
}
