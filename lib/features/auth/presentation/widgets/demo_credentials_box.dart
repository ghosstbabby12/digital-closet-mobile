import 'package:flutter/material.dart';

import 'package:closet_ai/core/config/demo_account.dart';

/// Box with the demo account's credentials. Tapping it fills the login form.
class DemoCredentialsBox extends StatelessWidget {
  const DemoCredentialsBox({super.key, required this.onUse});

  final void Function(String email, String password) onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onUse(demoEmail, demoPassword),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.key_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Cuenta de prueba', style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary)),
                ],
              ),
              const SizedBox(height: 10),
              _CredentialRow(label: 'Correo', value: demoEmail),
              const SizedBox(height: 4),
              _CredentialRow(label: 'Contraseña', value: demoPassword),
              const SizedBox(height: 8),
              Text(
                'Toca aquí para llenar los campos',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: SelectableText(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
