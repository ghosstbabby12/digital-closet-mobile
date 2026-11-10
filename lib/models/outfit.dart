import 'garment.dart';

class Outfit {
  final int id;
  final String occasion;
  final double weatherTempC;
  final String weatherCondition;
  final String explanation;
  final List<Garment> garments;

  /// Evento del calendario para el que se armó ("Boda de Ana"); null en el outfit del día.
  final String? eventTitle;
  final DateTime? eventDate;
  final DateTime createdAt;

  Outfit({
    required this.id,
    required this.occasion,
    required this.weatherTempC,
    required this.weatherCondition,
    required this.explanation,
    required this.garments,
    this.eventTitle,
    this.eventDate,
    required this.createdAt,
  });

  bool get isEvent => eventDate != null;

  /// Día en que aparece en el calendario: el del evento o, si no, el día en que se generó.
  DateTime get calendarDay {
    final day = eventDate ?? createdAt.toLocal();
    return DateTime(day.year, day.month, day.day);
  }

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'] as int,
      occasion: json['occasion'] as String,
      weatherTempC: (json['weather_temp_c'] as num).toDouble(),
      weatherCondition: json['weather_condition'] as String,
      explanation: json['explanation'] as String,
      garments: (json['garments'] as List).map((g) => Garment.fromJson(g as Map<String, dynamic>)).toList(),
      eventTitle: json['event_title'] as String?,
      // Fecha sin hora ("2026-12-05"): se lee como día local, sin zona horaria.
      eventDate: json['event_date'] == null ? null : DateTime.parse(json['event_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
