import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/profile/presentation/screens/profile_screen.dart';
import 'package:closet_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:closet_ai/features/settings/presentation/controllers/theme_controller.dart';
import 'package:closet_ai/core/widgets/pill_tabs.dart';

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
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: const Text('Ver mi perfil', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
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
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
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
