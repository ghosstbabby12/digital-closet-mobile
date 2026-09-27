import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exception.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../state/outfit_provider.dart';
import '../state/weather_provider.dart';

class GenerateOutfitScreen extends ConsumerStatefulWidget {
  const GenerateOutfitScreen({super.key});

  @override
  ConsumerState<GenerateOutfitScreen> createState() => _GenerateOutfitScreenState();
}

class _GenerateOutfitScreenState extends ConsumerState<GenerateOutfitScreen> {
  String _occasion = occasionOptions.first;

  Future<void> _generate() async {
    final position = await ref.read(currentPositionProvider.future);
    if (!mounted) return;
    await ref.read(outfitGenerateProvider.notifier).generate(
          occasion: _occasion,
          lat: position.latitude,
          lon: position.longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);

    ref.listen(outfitGenerateProvider, (previous, next) {
      next.whenOrNull(
        data: (outfit) {
          if (outfit != null) {
            context.push('/outfit-result', extra: outfit).then((_) {
              ref.read(outfitGenerateProvider.notifier).reset();
            });
          }
        },
        error: (error, stackTrace) {
          final message = error is ApiException ? error.message : error.toString();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    final generating = ref.watch(outfitGenerateProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('¿Qué me pongo hoy?', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              'Elige la ocasión y la IA arma tu outfit con lo que ya tienes en el clóset.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _WeatherCard(weatherAsync: weatherAsync, onRetry: () => ref.refresh(weatherProvider)),
            const SizedBox(height: 24),
            Text('Ocasión', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: occasionOptions.map((occasion) {
                final selected = occasion == _occasion;
                return ChoiceChip(
                  label: Text(occasion),
                  selected: selected,
                  onSelected: (_) => setState(() => _occasion = occasion),
                  selectedColor: AppColors.ink,
                  labelStyle: TextStyle(color: selected ? AppColors.card : AppColors.ink),
                  backgroundColor: AppColors.card,
                  side: const BorderSide(color: AppColors.line),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: generating || weatherAsync.isLoading ? null : _generate,
              child: generating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Vestirme hoy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final AsyncValue weatherAsync;
  final VoidCallback onRetry;

  const _WeatherCard({required this.weatherAsync, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: weatherAsync.when(
          loading: () => const Row(
            children: [
              SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Consultando el clima de hoy...'),
            ],
          ),
          error: (error, stackTrace) => Row(
            children: [
              const Icon(Icons.cloud_off, color: AppColors.inkSoft),
              const SizedBox(width: 12),
              Expanded(child: Text(error.toString())),
              IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry),
            ],
          ),
          data: (weather) => Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 32, color: AppColors.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.tempC.round()}°C · ${weather.condition}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                    ),
                    if (weather.city.isNotEmpty) Text(weather.city),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
