import 'package:closet_ai/features/weather/domain/weather.dart';

extension WeatherJson on Weather {
  static Weather fromJson(Map<String, dynamic> json) => Weather(
    tempC: (json['temp_c'] as num).toDouble(),
    feelsLikeC: (json['feels_like_c'] as num).toDouble(),
    condition: json['condition'] as String,
    conditionMain: json['condition_main'] as String,
    city: json['city'] as String? ?? '',
  );
}

extension CityJson on City {
  static City fromJson(Map<String, dynamic> json) => City(
    name: json['name'] as String,
    state: json['state'] as String?,
    country: json['country'] as String,
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {'name': name, 'state': state, 'country': country, 'lat': lat, 'lon': lon};
}
