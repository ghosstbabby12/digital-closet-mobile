import 'package:flutter/material.dart';

import 'package:closet_ai/core/network/image_url.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/garment_labels.dart';

/// Large photo of a garment.
class GarmentPhoto extends StatelessWidget {
  final Garment garment;

  const GarmentPhoto({super.key, required this.garment});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SizedBox(
          height: 320,
          child: Image.network(
            fullImageUrl(garment.imageUrl),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.checkroom, size: 48)),
          ),
        ),
      ),
    );
  }
}

/// Read-only name, category, color and warmth.
class GarmentDetails extends StatelessWidget {
  final Garment garment;

  const GarmentDetails({super.key, required this.garment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(garment.displayName, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        _DetailRow(label: 'Categoría', value: garment.category.label),
        _DetailRow(label: 'Color', value: garment.color.isNotEmpty ? garment.color : 'Sin color'),
        _DetailRow(label: 'Nivel de abrigo', value: garment.warmth.label),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
