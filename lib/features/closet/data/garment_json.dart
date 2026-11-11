import 'package:closet_ai/features/closet/domain/garment.dart';

typedef Json = Map<String, dynamic>;

GarmentCategory _category(Object? value) => GarmentCategory.values.byName(value as String);

WarmthLevel _warmth(Object? value) => WarmthLevel.values.byName(value as String);

extension GarmentJson on Garment {
  static Garment fromJson(Json json) => Garment(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    category: _category(json['category']),
    color: json['color'] as String? ?? '',
    warmth: _warmth(json['warmth']),
    imageUrl: json['image_url'] as String,
    cutoutUrl: json['cutout_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

extension GarmentSuggestionJson on GarmentSuggestion {
  static GarmentSuggestion fromJson(Json json) => GarmentSuggestion(
    name: json['name'] as String,
    color: json['color'] as String,
    category: _category(json['category']),
    warmth: _warmth(json['warmth']),
  );
}
