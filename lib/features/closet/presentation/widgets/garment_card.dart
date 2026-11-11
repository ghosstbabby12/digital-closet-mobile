import 'package:flutter/material.dart';

import 'package:closet_ai/core/network/image_url.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/garment_labels.dart';

class GarmentCard extends StatelessWidget {
  final Garment garment;
  final VoidCallback? onTap;

  const GarmentCard({super.key, required this.garment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = garment.name.isNotEmpty ? garment.name : garment.category.label;
    return Semantics(
      button: onTap != null,
      label: label,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: GarmentTile(garment: garment, radius: 20)),
        const SizedBox(height: 8),
        Text(
          garment.name.isNotEmpty ? garment.name : garment.category.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
        Text(
          garment.color.isNotEmpty ? garment.color : ' ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A garment photo filling a soft box with rounded corners.
class GarmentTile extends StatelessWidget {
  final Garment garment;
  final double radius;

  const GarmentTile({super.key, required this.garment, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Image.network(
          fullImageUrl(garment.imageUrl),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              Center(child: Icon(Icons.checkroom, color: scheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}
