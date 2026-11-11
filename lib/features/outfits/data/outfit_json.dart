import 'package:closet_ai/features/closet/data/garment_json.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';

extension OutfitJson on Outfit {
  static Outfit fromJson(Json json) => Outfit(
    id: json['id'] as int,
    occasion: json['occasion'] as String,
    weatherTempC: (json['weather_temp_c'] as num).toDouble(),
    weatherCondition: json['weather_condition'] as String,
    explanation: json['explanation'] as String,
    garments: [for (final garment in json['garments'] as List) GarmentJson.fromJson(garment as Json)],
    eventTitle: json['event_title'] as String?,
    // A date without time ("2026-12-05"): read as a local day, with no time zone.
    eventDate: json['event_date'] == null ? null : DateTime.parse(json['event_date'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
