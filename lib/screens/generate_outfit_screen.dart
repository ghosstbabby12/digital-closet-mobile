import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../core/weather_text.dart';
import '../models/garment.dart';
import '../models/outfit.dart';
import '../models/weather.dart';
import '../state/city_provider.dart';
import '../state/closet_provider.dart';
import '../state/outfit_provider.dart';
import '../state/weather_provider.dart';
import '../widgets/city_search_sheet.dart';
import '../widgets/garment_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_header.dart';
import 'garment_detail_screen.dart';

/// Ícono de cada ocasión, en el mismo orden que [occasionOptions].
const _occasionIcons = {
  'casual': Icons.weekend_outlined,
  'trabajo': Icons.work_outline,
  'fiesta': Icons.celebration_outlined,
  'deportivo': Icons.directions_run,
  'formal': Icons.diamond_outlined,
};

String _capitalized(String text) => '${text[0].toUpperCase()}${text.substring(1)}';

class GenerateOutfitScreen extends ConsumerStatefulWidget {
  const GenerateOutfitScreen({super.key});

  @override
  ConsumerState<GenerateOutfitScreen> createState() => _GenerateOutfitScreenState();
}

class _GenerateOutfitScreenState extends ConsumerState<GenerateOutfitScreen> {
  String _occasion = occasionOptions.first;

  Future<void> _generate(City city) async {
    await ref.read(outfitGenerateProvider.notifier).generate(occasion: _occasion, lat: city.lat, lon: city.lon);
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final city = ref.watch(selectedCityProvider);
    final garments = ref.watch(closetProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
    final closetEmpty = garments.valueOrNull?.isEmpty ?? false;
    final canGenerate = city != null && weatherAsync.hasValue && garments.hasValue && !closetEmpty;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: '¿Qué me pongo hoy?'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Elige la ocasión y armamos tu outfit con lo que ya tienes.',
                    style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WeatherCard(
                    city: city,
                    weatherAsync: weatherAsync,
                    onChangeCity: () => showCitySearchSheet(context),
                    onRetry: () => ref.invalidate(weatherProvider),
                  ),
                ),
                const SizedBox(height: 22),
                _OccasionCarousel(selected: _occasion, onSelected: (occasion) => setState(() => _occasion = occasion)),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ClosetPreview(generating: generating),
                ),
              ],
            ),
          ),
          // Fijo sobre la barra inferior, al alcance del pulgar.
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 92),
            child: PrimaryButton(
              label: 'Armar mi outfit',
              icon: Icons.auto_awesome,
              loading: generating,
              loadingLabel: 'Armando tu outfit...',
              onPressed: canGenerate ? () => _generate(city) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ciudad, temperatura y un consejo para vestirse, en una sola tarjeta.
class _WeatherCard extends StatelessWidget {
  final City? city;
  final AsyncValue<Weather?> weatherAsync;
  final VoidCallback onChangeCity;
  final VoidCallback onRetry;

  const _WeatherCard({
    required this.city,
    required this.weatherAsync,
    required this.onChangeCity,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final city = this.city;
    if (city == null) {
      return _frame(
        context,
        icon: Icons.location_off_outlined,
        title: '¿Dónde estás hoy?',
        subtitle: 'Elige tu ciudad para que el Estilista tenga en cuenta el clima.',
        action: TextButton(onPressed: onChangeCity, child: const Text('Elegir ciudad')),
      );
    }
    final change = TextButton(onPressed: onChangeCity, child: const Text('Cambiar'));
    return weatherAsync.when(
      loading: () => _frame(
        context,
        leading: const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        title: city.name,
        subtitle: 'Consultando el clima...',
        action: change,
      ),
      error: (error, stackTrace) => _frame(
        context,
        icon: Icons.cloud_off_outlined,
        title: city.name,
        subtitle: 'No pudimos consultar el clima.',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(tooltip: 'Reintentar', icon: const Icon(Icons.refresh), onPressed: onRetry),
            change,
          ],
        ),
      ),
      data: (weather) {
        if (weather == null) return const SizedBox.shrink();
        final condition = friendlyCondition(weather.condition);
        return _frame(
          context,
          icon: weatherIcon(weather.conditionMain),
          iconLabel: condition,
          // Se muestra el nombre elegido: OpenWeather a veces devuelve el de un barrio cercano.
          title: '${weather.tempC.round()}° en ${city.name}',
          subtitle: '$condition. ${weatherAdvice(weather)}.',
          action: change,
        );
      },
    );
  }

  Widget _frame(
    BuildContext context, {
    IconData? icon,
    String? iconLabel,
    Widget? leading,
    required String title,
    required String subtitle,
    required Widget action,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        child: Row(
          children: [
            leading ?? Icon(icon, color: scheme.primary, size: 26, semanticLabel: iconLabel),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodyMedium),
                ],
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }
}

class _OccasionCarousel extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _OccasionCarousel({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: occasionOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final occasion = occasionOptions[index];
          final isSelected = occasion == selected;
          final color = isSelected ? scheme.onPrimary : scheme.onSurface;
          return ChoiceChip(
            avatar: Icon(_occasionIcons[occasion] ?? Icons.checkroom_outlined, size: 18, color: color),
            label: Text(_capitalized(occasion)),
            selected: isSelected,
            onSelected: (_) => onSelected(occasion),
            labelStyle: TextStyle(fontWeight: FontWeight.w600, color: color),
          );
        },
      ),
    );
  }
}

/// Muestra el clóset bajo el botón: lo que no te has puesto últimamente o tu
/// último outfit. Con el clóset vacío, invita a agregar las primeras prendas.
class _ClosetPreview extends ConsumerWidget {
  final bool generating;

  const _ClosetPreview({required this.generating});

  static const _recentDays = 14;
  static const _maxItems = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final garmentsAsync = ref.watch(closetProvider);
    final history = ref.watch(outfitHistoryProvider).valueOrNull ?? const <Outfit>[];

    return garmentsAsync.when(
      loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('No pudimos cargar tu clóset.'),
          trailing: TextButton(
            onPressed: () => ref.read(closetProvider.notifier).load(),
            child: const Text('Reintentar'),
          ),
        ),
      ),
      data: (garments) {
        if (garments.isEmpty) return const _EmptyCloset();
        final (title, items) = _pick(garments, history);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(generating ? 'Combinando tus prendas...' : title, style: textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < _maxItems; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: i < items.length
                            ? _PreviewTile(garment: items[i], dimmed: generating)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
                if (generating) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Prendas sin usar en los outfits de las últimas dos semanas, las más
  /// olvidadas primero; si todo se usó, el último outfit.
  (String, List<Garment>) _pick(List<Garment> garments, List<Outfit> history) {
    final since = DateTime.now().subtract(const Duration(days: _recentDays));
    final worn = {
      for (final outfit in history)
        if (outfit.createdAt.isAfter(since)) ...outfit.garments.map((g) => g.id),
    };
    final forgotten = garments.where((g) => !worn.contains(g.id)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (forgotten.isNotEmpty) {
      return ('Lo que no te has puesto últimamente', forgotten.take(_maxItems).toList());
    }
    final last = history.isNotEmpty ? history.first : null;
    if (last != null && last.garments.isNotEmpty) {
      return ('Tu último outfit', last.garments.take(_maxItems).toList());
    }
    return ('En tu clóset', garments.take(_maxItems).toList());
  }
}

class _PreviewTile extends StatelessWidget {
  final Garment garment;
  final bool dimmed;

  const _PreviewTile({required this.garment, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final label = garment.name.isNotEmpty ? garment.name : garment.category.label;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => GarmentDetailScreen(garmentId: garment.id))),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.45 : 1,
          child: AspectRatio(aspectRatio: 0.8, child: GarmentTile(garment: garment)),
        ),
      ),
    );
  }
}

class _EmptyCloset extends StatelessWidget {
  const _EmptyCloset();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.checkroom_outlined, size: 40, color: scheme.primary),
            const SizedBox(height: 10),
            Text('Agrega tus primeras prendas', style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'El Estilista arma tus outfits con lo que tienes en el clóset. Empieza con 2 o 3 prendas.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => context.push('/add-garment'),
              icon: const Icon(Icons.add),
              label: const Text('Agregar prendas'),
            ),
          ],
        ),
      ),
    );
  }
}
