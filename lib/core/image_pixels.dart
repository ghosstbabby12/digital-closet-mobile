import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'silhouette.dart';

/// Descarga una imagen reducida (máximo [maxSide] px por lado) y devuelve sus
/// píxeles RGBA. Basta para medir siluetas y es rápido en el celular.
Future<RgbaPixels> loadPixels(String url, {int maxSide = 256}) async {
  final provider = ResizeImage(
    NetworkImage(url),
    width: maxSide,
    height: maxSide,
    policy: ResizeImagePolicy.fit,
  );
  final completer = Completer<ui.Image>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image.clone());
      stream.removeListener(listener);
    },
    onError: (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);

  final image = await completer.future.timeout(const Duration(seconds: 20));
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (bytes == null) throw StateError('No se pudieron leer los píxeles.');
    return RgbaPixels(bytes.buffer.asUint8List(), image.width, image.height);
  } finally {
    image.dispose();
  }
}
