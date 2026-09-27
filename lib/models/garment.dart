enum GarmentCategory { top, bottom, dress, outerwear, shoes, accessory }

enum WarmthLevel { light, medium, heavy }

extension GarmentCategoryLabel on GarmentCategory {
  String get label {
    switch (this) {
      case GarmentCategory.top:
        return 'Parte de arriba';
      case GarmentCategory.bottom:
        return 'Parte de abajo';
      case GarmentCategory.dress:
        return 'Vestido';
      case GarmentCategory.outerwear:
        return 'Abrigo / chamarra';
      case GarmentCategory.shoes:
        return 'Calzado';
      case GarmentCategory.accessory:
        return 'Accesorio';
    }
  }
}

extension WarmthLevelLabel on WarmthLevel {
  String get label {
    switch (this) {
      case WarmthLevel.light:
        return 'Ligera (calor)';
      case WarmthLevel.medium:
        return 'Media (entretiempo)';
      case WarmthLevel.heavy:
        return 'Abrigadora (frío)';
    }
  }
}

GarmentCategory categoryFromString(String value) =>
    GarmentCategory.values.firstWhere((e) => e.name == value);

WarmthLevel warmthFromString(String value) =>
    WarmthLevel.values.firstWhere((e) => e.name == value);

class Garment {
  final int id;
  final String name;
  final GarmentCategory category;
  final String color;
  final WarmthLevel warmth;
  final String imageUrl;
  final DateTime createdAt;

  Garment({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.warmth,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Garment.fromJson(Map<String, dynamic> json) {
    return Garment(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: categoryFromString(json['category'] as String),
      color: json['color'] as String? ?? '',
      warmth: warmthFromString(json['warmth'] as String),
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
