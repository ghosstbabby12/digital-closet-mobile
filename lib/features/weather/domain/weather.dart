class Weather {
  final double tempC;
  final double feelsLikeC;

  /// OpenWeather's description in Spanish ("algo de nubes").
  final String condition;

  /// OpenWeather's group in English ("Clouds", "Rain").
  final String conditionMain;
  final String city;

  Weather({
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.conditionMain,
    required this.city,
  });
}

/// The city whose weather the stylist uses.
class City {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  City({required this.name, this.state, required this.country, required this.lat, required this.lon});

  /// E.g. "Medellín, Antioquia, CO".
  String get label => [name, if (state != null && state!.isNotEmpty) state!, country].join(', ');
}
