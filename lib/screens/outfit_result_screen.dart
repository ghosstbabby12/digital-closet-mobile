import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/garment.dart';
import '../models/outfit.dart';
import '../state/try_on_request_provider.dart';
import '../widgets/garment_card.dart';
import '../widgets/primary_button.dart';

class OutfitResultScreen extends ConsumerWidget {
  final Outfit outfit;

  const OutfitResultScreen({super.key, required this.outfit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu outfit de hoy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${outfit.occasion[0].toUpperCase()}${outfit.occasion.substring(1)}')),
                Chip(label: Text('${outfit.weatherTempC.round()}°C · ${outfit.weatherCondition}')),
              ],
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.8,
              ),
              itemCount: outfit.garments.length,
              itemBuilder: (context, index) {
                final garment = outfit.garments[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: GarmentTile(garment: garment, radius: 20)),
                    const SizedBox(height: 8),
                    Text(
                      garment.name.isNotEmpty ? garment.name : garment.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por qué esta combinación', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(outfit.explanation, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Probar cómo me queda',
              onPressed: () {
                ref.read(tryOnRequestProvider.notifier).state = outfit.garments;
                context.pop();
              },
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.pop(), child: const Text('Listo')),
          ],
        ),
      ),
    );
  }
}
