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
