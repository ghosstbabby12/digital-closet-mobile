import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/weather/domain/weather.dart';
import 'package:closet_ai/features/weather/domain/weather_text.dart';
import 'package:closet_ai/features/weather/presentation/weather_icon.dart';

/// City, temperature and a dressing tip in one card, with a discreet "Cambiar" action.
class WeatherCard extends StatelessWidget {
  final City? city;
  final AsyncValue<Weather?> weather;
  final VoidCallback onChangeCity;
  final VoidCallback onRetry;

  const WeatherCard({
    super.key,
    required this.city,
    required this.weather,
    required this.onChangeCity,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final city = this.city;
    if (city == null) {
      return _WeatherFrame(
        icon: Icons.location_off_outlined,
        title: '¿Dónde estás hoy?',
        subtitle: 'Elige tu ciudad para que el Estilista tenga en cuenta el clima.',
        action: TextButton(onPressed: onChangeCity, child: const Text('Elegir ciudad')),
      );
    }
    final change = TextButton(onPressed: onChangeCity, child: const Text('Cambiar'));
    return weather.when(
      loading: () => _WeatherFrame(
        leading: const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        title: city.name,
        subtitle: 'Consultando el clima...',
        action: change,
      ),
      error: (error, stackTrace) => _WeatherFrame(
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
        return _WeatherFrame(
          icon: weatherIcon(weather.conditionMain),
          iconLabel: condition,
          // The chosen city's name: OpenWeather sometimes returns a nearby neighborhood.
          title: '${weather.tempC.round()}° en ${city.name}',
          subtitle: '$condition. ${weatherAdvice(weather)}.',
          action: change,
        );
      },
    );
  }
}

class _WeatherFrame extends StatelessWidget {
  final IconData? icon;
  final String? iconLabel;
  final Widget? leading;
  final String title;
  final String subtitle;
  final Widget action;

  const _WeatherFrame({
    this.icon,
    this.iconLabel,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
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
