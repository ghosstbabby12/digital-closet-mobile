class Weather {
  final double tempC;
  final double feelsLikeC;
  final String condition;
  final String conditionMain;
  final String city;

  Weather({
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.conditionMain,
    required this.city,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      tempC: (json['temp_c'] as num).toDouble(),
      feelsLikeC: (json['feels_like_c'] as num).toDouble(),
      condition: json['condition'] as String,
      conditionMain: json['condition_main'] as String,
      city: json['city'] as String? ?? '',
    );
  }
}

/// Ciudad elegida para consultar el clima en vez de la ubicación del teléfono.
class City {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  City({required this.name, this.state, required this.country, required this.lat, required this.lon});

  /// Ej.: "Medellín, Antioquia, CO".
  String get label => [name, if (state != null && state!.isNotEmpty) state!, country].join(', ');

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      state: json['state'] as String?,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'state': state, 'country': country, 'lat': lat, 'lon': lon};
}
