import 'package:flutter/material.dart';

/// Icon for an OpenWeather condition group ("Clear", "Rain"...).
IconData weatherIcon(String main) => switch (main) {
  'Clear' => Icons.wb_sunny_outlined,
  'Clouds' => Icons.cloud_outlined,
  'Rain' || 'Drizzle' => Icons.water_drop_outlined,
  'Thunderstorm' => Icons.thunderstorm_outlined,
  'Snow' => Icons.ac_unit,
  _ => Icons.foggy,
};
