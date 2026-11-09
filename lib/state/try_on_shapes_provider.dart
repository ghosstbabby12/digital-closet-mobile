import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/image_pixels.dart';
import '../core/silhouette.dart';

/// Mide la silueta del cuerpo y la forma de cada prenda para colocarlas solas.
/// Devuelve null si no se puede medir; el probador sigue funcionando a mano.
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
