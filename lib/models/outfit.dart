import 'garment.dart';

class Outfit {
  final int id;
  final String occasion;
  final double weatherTempC;
  final String weatherCondition;
  final String explanation;
  final List<Garment> garments;
  final DateTime createdAt;

  Outfit({
    required this.id,
    required this.occasion,
    required this.weatherTempC,
    required this.weatherCondition,
    required this.explanation,
    required this.garments,
    required this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'] as int,
      occasion: json['occasion'] as String,
      weatherTempC: (json['weather_temp_c'] as num).toDouble(),
      weatherCondition: json['weather_condition'] as String,
      explanation: json['explanation'] as String,
      garments: (json['garments'] as List)
          .map((g) => Garment.fromJson(g as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
