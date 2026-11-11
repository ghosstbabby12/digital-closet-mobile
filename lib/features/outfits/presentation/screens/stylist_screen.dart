import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:closet_ai/core/widgets/error_snackbar.dart';
import 'package:closet_ai/core/widgets/primary_button.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:closet_ai/features/home/presentation/widgets/screen_header.dart';
import 'package:closet_ai/features/outfits/domain/occasion.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:closet_ai/features/outfits/presentation/controllers/outfit_controller.dart';
import 'package:closet_ai/features/outfits/presentation/widgets/closet_highlights_card.dart';
import 'package:closet_ai/features/outfits/presentation/widgets/occasion_carousel.dart';
import 'package:closet_ai/features/weather/domain/weather.dart';
import 'package:closet_ai/features/weather/presentation/controllers/city_controller.dart';
import 'package:closet_ai/features/weather/presentation/controllers/weather_controller.dart';
import 'package:closet_ai/features/weather/presentation/widgets/city_search_sheet.dart';
import 'package:closet_ai/features/weather/presentation/widgets/weather_card.dart';

/// "¿Qué me pongo hoy?": weather, occasion and the button that builds the outfit.
class StylistScreen extends ConsumerStatefulWidget {
  const StylistScreen({super.key});

  @override
  ConsumerState<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends ConsumerState<StylistScreen> {
  String _occasion = occasionOptions.first;

  void _generate(City city) =>
      ref.read(outfitGenerateProvider.notifier).generate(occasion: _occasion, lat: city.lat, lon: city.lon);

  void _onOutfitState(AsyncValue<Outfit?>? previous, AsyncValue<Outfit?> next) => next.whenOrNull(
    data: (outfit) {
      if (outfit == null) return;
      ref.invalidate(outfitHistoryProvider);
      context.push('/outfit-result', extra: outfit).then((_) => ref.read(outfitGenerateProvider.notifier).reset());
    },
    error: (error, stackTrace) => showErrorSnackBar(context, error),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(outfitGenerateProvider, _onOutfitState);
    final weather = ref.watch(weatherProvider);
    final city = ref.watch(selectedCityProvider);
    final closet = ref.watch(closetProvider);
    final generating = ref.watch(outfitGenerateProvider).isLoading;
    final canGenerate = city != null && weather.hasValue && (closet.valueOrNull?.isNotEmpty ?? false);

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
                _padded(
                  Text(
                    'Elige la ocasión y armamos tu outfit con lo que ya tienes.',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                _padded(
                  WeatherCard(
                    city: city,
                    weather: weather,
                    onChangeCity: () => showCitySearchSheet(context),
                    onRetry: () => ref.invalidate(weatherProvider),
                  ),
                ),
                const SizedBox(height: 22),
                OccasionCarousel(selected: _occasion, onSelected: (value) => setState(() => _occasion = value)),
                const SizedBox(height: 22),
                _padded(ClosetHighlightsCard(generating: generating)),
              ],
            ),
          ),
          // Pinned right above the bottom bar, within thumb reach.
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

  Widget _padded(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);
}
