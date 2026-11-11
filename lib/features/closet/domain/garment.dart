enum GarmentCategory { top, bottom, dress, outerwear, shoes, accessory }

enum WarmthLevel { light, medium, heavy }

/// Details suggested from a garment's photo.
class GarmentSuggestion {
  final String name;
  final String color;
  final GarmentCategory category;
  final WarmthLevel warmth;

  GarmentSuggestion({required this.name, required this.color, required this.category, required this.warmth});
}

class Garment {
  final int id;
  final String name;
  final GarmentCategory category;
  final String color;
  final WarmthLevel warmth;
  final String imageUrl;
  final String? cutoutUrl;
  final DateTime createdAt;

  Garment({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.warmth,
    required this.imageUrl,
    this.cutoutUrl,
    required this.createdAt,
  });
}
