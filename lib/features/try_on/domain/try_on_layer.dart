import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/try_on/domain/silhouette.dart';

const minLayerWidth = 0.12;
const maxLayerWidth = 1.0;

/// A garment placed on the photo. Position and width are fractions of the stage,
/// so they do not change with the screen size.
class TryOnLayer {
  final Garment garment;
  final double centerX;
  final double top;
  final double width;

  /// Visible area of the cutout; null until it has been measured.
  final GarmentShape? shape;

  /// True until the user moves or resizes it, so automatic fitting never undoes their changes.
  final bool autoFit;

  const TryOnLayer({
    required this.garment,
    required this.centerX,
    required this.top,
    required this.width,
    this.shape,
    this.autoFit = true,
  });

  /// Rough starting position, based on the body part the garment goes on.
  factory TryOnLayer.initial(Garment garment) {
    final (top, width) = switch (garment.category) {
      GarmentCategory.top => (0.18, 0.5),
      GarmentCategory.outerwear => (0.17, 0.55),
      GarmentCategory.dress => (0.18, 0.55),
      GarmentCategory.bottom => (0.45, 0.45),
      GarmentCategory.shoes => (0.86, 0.32),
      GarmentCategory.accessory => (0.1, 0.22),
    };
    return TryOnLayer(garment: garment, centerX: 0.5, top: top, width: width);
  }

  int get garmentId => garment.id;

  TryOnLayer copyWith({double? centerX, double? top, double? width, GarmentShape? shape, bool? autoFit}) => TryOnLayer(
    garment: garment,
    centerX: centerX ?? this.centerX,
    top: top ?? this.top,
    width: width ?? this.width,
    shape: shape ?? this.shape,
    autoFit: autoFit ?? this.autoFit,
  );
}
