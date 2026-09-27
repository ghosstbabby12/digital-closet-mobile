import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/image_url.dart';
import '../state/outfit_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(outfitHistoryProvider);
    final dateFormat = DateFormat('d MMM, HH:mm', 'es');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(outfitHistoryProvider.future),
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('No se pudo cargar tu historial:\n$error', textAlign: TextAlign.center)),
            ],
          ),
          data: (outfits) {
            if (outfits.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Aún no has generado ningún outfit.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: outfits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final outfit = outfits[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${outfit.occasion[0].toUpperCase()}${outfit.occasion.substring(1)}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Text(dateFormat.format(outfit.createdAt.toLocal())),
                          ],
                        ),
                        Text(
                          '${outfit.weatherTempC.round()}°C · ${outfit.weatherCondition}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: outfit.garments.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fullImageUrl(outfit.garments[index].imageUrl),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 64,
                                  height: 64,
                                  color: AppColors.line,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(outfit.explanation, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
