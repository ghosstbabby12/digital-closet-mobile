import 'package:flutter/material.dart';

import 'package:closet_ai/features/settings/presentation/widgets/settings_sheet.dart';

/// Tab header: large title, actions and the settings button.
class ScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const ScreenHeader({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
          ...actions.expand((action) => [action, const SizedBox(width: 8)]),
          HeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Ajustes',
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HeaderIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: scheme.onSurface),
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface,
        fixedSize: const Size.square(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
