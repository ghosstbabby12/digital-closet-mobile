import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_provider.dart';
import '../state/theme_provider.dart';
import 'pill_tabs.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(context: context, builder: (context) => const _SettingsSheet());
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Text('Apariencia', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            PillTabs(
              labels: const ['Claro', 'Oscuro', 'Sistema'],
              selectedIndex: _modes.indexOf(mode),
              onSelected: (index) => ref.read(themeModeProvider.notifier).setMode(_modes[index]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Cerrar sesión', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
