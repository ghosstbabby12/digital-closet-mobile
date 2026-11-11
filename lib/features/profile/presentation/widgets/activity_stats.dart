import 'package:flutter/material.dart';

import 'package:closet_ai/features/profile/domain/profile.dart';

/// Totals of garments, outfits and looks.
class ActivityStats extends StatelessWidget {
  final Profile profile;

  const ActivityStats({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Stat(value: profile.garmentCount, label: 'Prendas'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(value: profile.outfitCount, label: 'Outfits'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(value: profile.lookCount, label: 'Looks'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('$value', style: textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
