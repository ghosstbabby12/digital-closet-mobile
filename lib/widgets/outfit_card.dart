import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/outfit.dart';
import 'garment_card.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;

  /// Si se pasa, la tarjeta muestra un botón para borrar el outfit.
  final VoidCallback? onDelete;

  const OutfitCard({super.key, required this.outfit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final occasion = '${outfit.occasion[0].toUpperCase()}${outfit.occasion.substring(1)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (outfit.isEvent) ...[
                  Icon(Icons.event_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(child: Text(outfit.eventTitle ?? occasion, style: textTheme.titleLarge)),
                Text(
                  outfit.isEvent
                      ? DateFormat("d MMM", 'es').format(outfit.eventDate!)
                      : DateFormat('d MMM, HH:mm', 'es').format(outfit.createdAt.toLocal()),
                  style: textTheme.bodySmall,
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: outfit.isEvent ? 'Borrar evento' : 'Borrar outfit',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              [
                if (outfit.isEvent) occasion,
                '${outfit.weatherTempC.round()}°C · ${outfit.weatherCondition}',
              ].join(' · '),
              style: textTheme.bodySmall,
            ),
            if (outfit.garments.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: outfit.garments.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) =>
                      SizedBox(width: 92, child: GarmentTile(garment: outfit.garments[index])),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(outfit.explanation, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
