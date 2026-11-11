import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/try_on/data/image_pixels.dart';
import 'package:closet_ai/features/try_on/domain/silhouette.dart';

/// Measures the body silhouette and each garment's shape so they can be placed automatically.
/// Returns null when something cannot be measured; the try-on still works by hand.
abstract class ShapeLoader {
  Future<BodyShape?> body(String url);
  Future<GarmentShape?> garment(String url);
}

class NetworkShapeLoader implements ShapeLoader {
  final Map<String, Future<BodyShape?>> _bodies = {};
  final Map<String, Future<GarmentShape?>> _garments = {};

  @override
  Future<BodyShape?> body(String url) => _bodies.putIfAbsent(url, () async {
    try {
      return analyzeBody(await loadPixels(url));
    } catch (_) {
      return null;
    }
  });

  @override
  Future<GarmentShape?> garment(String url) => _garments.putIfAbsent(url, () async {
    try {
      return analyzeGarment(await loadPixels(url));
    } catch (_) {
      return null;
    }
  });
}

final shapeLoaderProvider = Provider<ShapeLoader>((ref) => NetworkShapeLoader());
