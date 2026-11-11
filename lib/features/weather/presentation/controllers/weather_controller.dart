import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/weather/domain/weather.dart';
import 'package:closet_ai/features/weather/data/weather_repository.dart';
import 'package:closet_ai/features/weather/presentation/controllers/city_controller.dart';

/// Weather of the chosen city, or null while none has been chosen.
final weatherProvider = FutureProvider.autoDispose<Weather?>((ref) async {
  final city = ref.watch(selectedCityProvider);
  if (city == null) return null;
  return ref.read(weatherRepositoryProvider).current(lat: city.lat, lon: city.lon);
});
