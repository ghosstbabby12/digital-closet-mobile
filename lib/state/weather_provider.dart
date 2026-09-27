import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/weather.dart';
import '../repositories/weather_repository.dart';

final currentPositionProvider = FutureProvider<Position>((ref) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Activa el GPS/ubicación del teléfono para consultar el clima.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw Exception('Se necesita permiso de ubicación para consultar el clima.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Permiso de ubicación denegado permanentemente. Actívalo en ajustes.');
  }

  return Geolocator.getCurrentPosition();
});

final weatherProvider = FutureProvider.autoDispose<Weather>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  final repository = ref.read(weatherRepositoryProvider);
  return repository.current(lat: position.latitude, lon: position.longitude);
});
