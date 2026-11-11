import 'package:flutter/material.dart';

import 'package:closet_ai/core/utils/text.dart';
import 'package:closet_ai/features/outfits/domain/occasion.dart';

const _icons = {
  'casual': Icons.weekend_outlined,
  'trabajo': Icons.work_outline,
  'fiesta': Icons.celebration_outlined,
  'deportivo': Icons.directions_run,
  'formal': Icons.diamond_outlined,
};

/// Horizontal row of occasion chips, each with its icon.
class OccasionCarousel extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const OccasionCarousel({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: occasionOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final occasion = occasionOptions[index];
          final isSelected = occasion == selected;
          final color = isSelected ? scheme.onPrimary : scheme.onSurface;
          return ChoiceChip(
            avatar: Icon(_icons[occasion] ?? Icons.checkroom_outlined, size: 18, color: color),
            label: Text(capitalized(occasion)),
            selected: isSelected,
            onSelected: (_) => onSelected(occasion),
            labelStyle: TextStyle(fontWeight: FontWeight.w600, color: color),
          );
        },
      ),
    );
  }
}
