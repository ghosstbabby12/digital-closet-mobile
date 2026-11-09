import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather.dart';
import '../repositories/weather_repository.dart';
import 'city_provider.dart';

/// Clima de la ciudad elegida, o null si todavía no se ha elegido ninguna.
final weatherProvider = FutureProvider.autoDispose<Weather?>((ref) async {
  final city = ref.watch(selectedCityProvider);
  if (city == null) return null;
  return ref.read(weatherRepositoryProvider).current(lat: city.lat, lon: city.lon);
});
