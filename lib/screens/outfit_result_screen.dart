import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../core/image_url.dart';
import '../models/garment.dart';
import '../models/outfit.dart';

class OutfitResultScreen extends StatelessWidget {
  final Outfit outfit;

  const OutfitResultScreen({super.key, required this.outfit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu outfit de hoy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(outfit.occasion), backgroundColor: AppColors.card),
                Chip(
                  label: Text('${outfit.weatherTempC.round()}°C · ${outfit.weatherCondition}'),
                  backgroundColor: AppColors.card,
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.8,
              ),
              itemCount: outfit.garments.length,
              itemBuilder: (context, index) {
                final garment = outfit.garments[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.network(fullImageUrl(garment.imageUrl), fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          garment.name.isNotEmpty ? garment.name : garment.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por qué esta combinación', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(outfit.explanation, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }
}
