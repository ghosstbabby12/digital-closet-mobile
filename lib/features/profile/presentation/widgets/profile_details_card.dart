import 'package:flutter/material.dart';

import 'package:closet_ai/features/profile/domain/profile.dart';

/// Name, email and phone, one per row.
class ProfileDetailsCard extends StatelessWidget {
  final Profile profile;

  const ProfileDetailsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            _DetailRow(icon: Icons.person_outline, label: 'Nombre', value: profile.name ?? 'Sin nombre'),
            _DetailRow(icon: Icons.mail_outline, label: 'Correo', value: profile.email),
            _DetailRow(icon: Icons.phone_outlined, label: 'Teléfono', value: profile.phone ?? 'Sin teléfono'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
