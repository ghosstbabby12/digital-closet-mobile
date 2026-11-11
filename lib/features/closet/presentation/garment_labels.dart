import 'package:closet_ai/features/closet/domain/garment.dart';

/// Spanish names shown in the app for each category and warmth level.
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

extension GarmentDisplayName on Garment {
  /// The name, or the category when the garment has none.
  String get displayName => name.isNotEmpty ? name : category.label;
}
