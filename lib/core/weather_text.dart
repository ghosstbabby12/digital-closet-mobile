import 'package:flutter/material.dart';

import '../models/weather.dart';

/// Textos de OpenWeather en español ("algo de nubes", "nubes rotas") pasados a
/// frases naturales. Si llega uno desconocido se usa tal cual, con mayúscula.
const _conditions = {
  'cielo claro': 'Despejado',
  'despejado': 'Despejado',
  'algo de nubes': 'Algo nublado',
  'nubes dispersas': 'Parcialmente nublado',
  'nubes rotas': 'Mayormente nublado',
  'muy nuboso': 'Mayormente nublado',
  'nubes': 'Nublado',
  'nuboso': 'Nublado',
  'llovizna': 'Llovizna',
  'llovizna ligera': 'Llovizna',
  'lluvia ligera': 'Lluvia ligera',
  'lluvia moderada': 'Lluvia',
  'lluvia': 'Lluvia',
  'lluvia de gran intensidad': 'Lluvia fuerte',
  'lluvia muy fuerte': 'Lluvia fuerte',
  'tormenta': 'Tormenta',
  'tormenta con lluvia ligera': 'Tormenta',
  'tormenta con lluvia': 'Tormenta',
  'nieve': 'Nieve',
  'nevada ligera': 'Nieve ligera',
  'niebla': 'Niebla',
  'bruma': 'Neblina',
  'neblina': 'Neblina',
  'calima': 'Bruma',
  'humo': 'Humo',
};

String friendlyCondition(String description) {
  final text = description.trim().toLowerCase();
  final known = _conditions[text];
  if (known != null) return known;
  if (text.isEmpty) return '';
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

bool _isWet(String main) => const {'Rain', 'Drizzle', 'Thunderstorm', 'Snow'}.contains(main);

/// Consejo corto para vestirse según la sensación térmica y la lluvia,
/// ej. "Fresco: lleva una capa ligera".
String weatherAdvice(Weather weather) {
  final feels = weather.feelsLikeC;
  final base = switch (feels) {
    < 8 => 'Frío: abrígate con capas y una chaqueta gruesa',
    < 14 => 'Fresco: lleva una chaqueta',
    < 19 => 'Templado: lleva una capa ligera',
    < 25 => 'Agradable: ropa ligera',
    _ => 'Calor: ropa fresca y transpirable',
  };
  return _isWet(weather.conditionMain) ? '$base, y algo para la lluvia' : base;
}

IconData weatherIcon(String main) => switch (main) {
  'Clear' => Icons.wb_sunny_outlined,
  'Clouds' => Icons.cloud_outlined,
  'Rain' || 'Drizzle' => Icons.water_drop_outlined,
  'Thunderstorm' => Icons.thunderstorm_outlined,
  'Snow' => Icons.ac_unit,
  _ => Icons.foggy,
};
