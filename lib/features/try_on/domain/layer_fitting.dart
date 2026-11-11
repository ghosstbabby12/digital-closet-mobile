import 'dart:ui' show Size;

import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/try_on/domain/silhouette.dart';
import 'package:closet_ai/features/try_on/domain/try_on_layer.dart';

/// Places a layer on the body silhouette. Returns it unchanged while measurements are missing.
TryOnLayer fitLayer(TryOnLayer layer, BodyShape? body, Size? stage) {
  final shape = layer.shape;
  if (body == null || shape == null || stage == null) return layer;
  final fit = fitGarment(layer.garment.category, body, shape);
  if (fit == null) return layer;

  // The photo is shown whole (BoxFit.contain) and centered on the stage.
  final stageAspect = stage.width / stage.height;
  final photoWidth = stageAspect > body.imageAspect ? body.imageAspect / stageAspect : 1.0;
  final photoHeight = stageAspect > body.imageAspect ? 1.0 : stageAspect / body.imageAspect;
  final photoLeft = (1 - photoWidth) / 2;
  final photoTop = (1 - photoHeight) / 2;
  return layer.copyWith(
    centerX: photoLeft + fit.centerX * photoWidth,
    top: photoTop + fit.top * photoHeight,
    width: (fit.width * photoWidth).clamp(minLayerWidth, maxLayerWidth),
    autoFit: true,
  );
}

/// Layers in wearing order (pants, blouse, jacket on top). Within a category the
/// list order wins, and the selected layer is always last.
List<TryOnLayer> inWearingOrder(List<TryOnLayer> layers) {
  final indexed = layers.indexed.toList()
    ..sort((a, b) {
      final byCategory = layerOrder(a.$2.garment.category).compareTo(layerOrder(b.$2.garment.category));
      return byCategory != 0 ? byCategory : a.$1.compareTo(b.$1);
    });
  return [for (final (_, layer) in indexed) layer];
}

/// Garments the AI try-on can dress; accessories are not supported.
bool canTryOnWithAi(Garment garment) => garment.category != GarmentCategory.accessory;
