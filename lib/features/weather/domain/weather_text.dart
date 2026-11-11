import 'package:closet_ai/core/utils/text.dart';

import 'package:closet_ai/features/weather/domain/weather.dart';

/// OpenWeather's Spanish descriptions ("algo de nubes", "nubes rotas") turned into
/// natural phrases. Unknown ones are used as they come, capitalized.
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
  return capitalized(text);
}

bool _isWet(String main) => const {'Rain', 'Drizzle', 'Thunderstorm', 'Snow'}.contains(main);

/// Short dressing advice from the feels-like temperature and rain,
/// e.g. "Fresco: lleva una capa ligera". Shown to the user, so it is in Spanish.
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
