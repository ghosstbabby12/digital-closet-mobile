import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/outfit.dart';
import 'garment_card.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;

  const OutfitCard({super.key, required this.outfit});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${outfit.occasion[0].toUpperCase()}${outfit.occasion.substring(1)}',
                    style: textTheme.titleLarge,
                  ),
                ),
                Text(
                  DateFormat('d MMM, HH:mm', 'es').format(outfit.createdAt.toLocal()),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('${outfit.weatherTempC.round()}°C · ${outfit.weatherCondition}', style: textTheme.bodySmall),
            if (outfit.garments.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: outfit.garments.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => SizedBox(
                    width: 92,
                    child: GarmentTile(garment: outfit.garments[index]),
                  ),
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
