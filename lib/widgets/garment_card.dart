import 'package:flutter/material.dart';

import '../core/image_url.dart';
import '../models/garment.dart';

class GarmentCard extends StatelessWidget {
  final Garment garment;
  final VoidCallback? onDelete;

  const GarmentCard({super.key, required this.garment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GarmentTile(garment: garment, radius: 20),
              if (onDelete != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    tooltip: 'Eliminar prenda',
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onDelete,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          garment.name.isNotEmpty ? garment.name : garment.category.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
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

/// Foto de una prenda que llena un recuadro suave con esquinas redondeadas.
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
