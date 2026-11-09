import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exception.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/weather.dart';
import '../state/city_provider.dart';
import '../state/outfit_provider.dart';
import '../state/weather_provider.dart';
import '../widgets/city_search_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_header.dart';

class GenerateOutfitScreen extends ConsumerStatefulWidget {
  const GenerateOutfitScreen({super.key});

  @override
  ConsumerState<GenerateOutfitScreen> createState() => _GenerateOutfitScreenState();
}

class _GenerateOutfitScreenState extends ConsumerState<GenerateOutfitScreen> {
  String _occasion = occasionOptions.first;

  Future<void> _generate() async {
    // Las mismas coordenadas del clima que se muestra: la ciudad elegida o el GPS.
    final coordinates = await ref.read(weatherCoordinatesProvider.future);
    if (!mounted) return;
    await ref.read(outfitGenerateProvider.notifier).generate(
          occasion: _occasion,
          lat: coordinates.lat,
          lon: coordinates.lon,
        );
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final city = ref.watch(selectedCityProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen(outfitGenerateProvider, (previous, next) {
      next.whenOrNull(
        data: (outfit) {
          if (outfit != null) {
            ref.invalidate(outfitHistoryProvider);
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

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Estilista'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, floatingNavClearance),
              children: [
                Text('¿Qué me pongo hoy?', style: textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'Elige la ocasión y arma tu outfit con lo que ya tienes en el clóset.',
                  style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 22),
                _LocationRow(city: city, onChange: () => showCitySearchSheet(context)),
                const SizedBox(height: 8),
                _WeatherCard(
                  weatherAsync: weatherAsync,
                  cityName: city?.name,
                  onRetry: () => ref.invalidate(weatherProvider),
                ),
                const SizedBox(height: 26),
                Text('Ocasión', style: textTheme.titleLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: occasionOptions.map((occasion) {
                    final selected = occasion == _occasion;
                    return ChoiceChip(
                      label: Text('${occasion[0].toUpperCase()}${occasion.substring(1)}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _occasion = occasion),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: selected ? scheme.onPrimary : scheme.onSurface,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Vestirme hoy',
                  loading: generating,
                  onPressed: weatherAsync.isLoading ? null : _generate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final City? city;
  final VoidCallback onChange;

  const _LocationRow({required this.city, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(city == null ? Icons.my_location : Icons.location_on_outlined, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            city?.label ?? 'Mi ubicación actual',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
        ),
        TextButton(onPressed: onChange, child: const Text('Cambiar ciudad')),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final AsyncValue weatherAsync;
  final String? cityName;
  final VoidCallback onRetry;

  const _WeatherCard({required this.weatherAsync, required this.cityName, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: weatherAsync.when(
          loading: () => const Row(
            children: [
              SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Expanded(child: Text('Consultando el clima de hoy...')),
            ],
          ),
          error: (error, stackTrace) => Row(
            children: [
              Icon(Icons.cloud_off, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(error.toString())),
              IconButton(tooltip: 'Reintentar', icon: const Icon(Icons.refresh), onPressed: onRetry),
            ],
          ),
          data: (weather) => IntrinsicHeight(
            child: Row(
              children: [
                _WeatherStat(label: 'Temperatura', value: '${weather.tempC.round()}°C'),
                const VerticalDivider(width: 20),
                _WeatherStat(label: 'Clima', value: weather.condition as String),
                // Con una ciudad elegida se muestra su nombre; OpenWeather a veces
                // devuelve el de un barrio o una estación cercana.
                if ((cityName ?? weather.city as String).isNotEmpty) ...[
                  const VerticalDivider(width: 20),
                  _WeatherStat(label: 'Ciudad', value: cityName ?? weather.city as String),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
