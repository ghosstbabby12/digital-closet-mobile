import 'package:closet_ai/features/closet/domain/garment.dart';

class Outfit {
  final int id;
  final String occasion;
  final double weatherTempC;
  final String weatherCondition;
  final String explanation;
  final List<Garment> garments;

  /// Calendar event the outfit was planned for ("Boda de Ana"); null for the outfit of the day.
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

  /// Day it shows on in the calendar: the event's day, or else the day it was generated.
  DateTime get calendarDay {
    final day = eventDate ?? createdAt.toLocal();
    return DateTime(day.year, day.month, day.day);
  }
}
