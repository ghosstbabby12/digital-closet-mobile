import 'dart:typed_data';

import '../models/garment.dart';

/// Píxeles RGBA de una imagen (4 bytes por píxel, sin premultiplicar).
class RgbaPixels {
  final Uint8List data;
  final int width;
  final int height;

  const RgbaPixels(this.data, this.width, this.height);

  int alphaAt(int x, int y) => data[(y * width + x) * 4 + 3];
}

/// Zona visible de una prenda recortada, sin los bordes transparentes.
/// Las posiciones son fracciones del tamaño de la imagen.
class GarmentShape {
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Alto / ancho de la zona visible, en píxeles reales.
  final double aspect;

  const GarmentShape({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.aspect,
  });
}

GarmentShape? analyzeGarment(RgbaPixels pixels, {int alphaThreshold = 40}) {
  var minX = pixels.width, minY = pixels.height, maxX = -1, maxY = -1;
  for (var y = 0; y < pixels.height; y++) {
    for (var x = 0; x < pixels.width; x++) {
      if (pixels.alphaAt(x, y) < alphaThreshold) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < 0) return null;
  final width = maxX - minX + 1;
  final height = maxY - minY + 1;
  return GarmentShape(
    left: minX / pixels.width,
    top: minY / pixels.height,
    right: (maxX + 1) / pixels.width,
    bottom: (maxY + 1) / pixels.height,
    aspect: height / width,
  );
}

/// Silueta de la persona en la foto recortada. Las posiciones son fracciones
/// del tamaño de la imagen.
class BodyShape {
  /// Ancho / alto de la imagen.
  final double imageAspect;

  /// Fila de la coronilla y de los pies.
  final double top;
  final double bottom;

  /// Tramo opaco central de cada fila (el cuerpo, sin brazos separados);
  /// null en las filas vacías.
  final List<({double left, double right})?> rows;

  const BodyShape({required this.imageAspect, required this.top, required this.bottom, required this.rows});

  double get height => bottom - top;

  /// Tramo central a una altura relativa del cuerpo (0 = cabeza, 1 = pies).
  ({double left, double right})? spanAt(double bodyFraction) {
    final y = top + bodyFraction.clamp(0.0, 1.0) * height;
    final index = (y * rows.length).floor().clamp(0, rows.length - 1);
    for (var offset = 0; offset < rows.length; offset++) {
      for (final i in [index - offset, index + offset]) {
        if (i >= 0 && i < rows.length && rows[i] != null) return rows[i];
      }
    }
    return null;
  }

  /// Ancho de los hombros: mediana del tramo central entre el 17 % y el 22 % del cuerpo.
  double get shoulderWidth {
    final widths = <double>[];
    for (var f = 0.17; f <= 0.22; f += 0.01) {
      final span = spanAt(f);
      if (span != null) widths.add(span.right - span.left);
    }
    if (widths.isEmpty) return 0;
    widths.sort();
    return widths[widths.length ~/ 2];
  }
}

BodyShape? analyzeBody(RgbaPixels pixels, {int alphaThreshold = 128}) {
  final spansByRow = <List<(int, int)>>[];
  int? firstRow, lastRow;
  for (var y = 0; y < pixels.height; y++) {
    final spans = <(int, int)>[];
    int? start;
    for (var x = 0; x <= pixels.width; x++) {
      final opaque = x < pixels.width && pixels.alphaAt(x, y) >= alphaThreshold;
      if (opaque && start == null) start = x;
      if (!opaque && start != null) {
        spans.add((start, x - 1));
        start = null;
      }
    }
    spansByRow.add(spans);
    if (spans.isNotEmpty) {
      firstRow ??= y;
      lastRow = y;
    }
  }
  if (firstRow == null || lastRow == null) return null;
  // Una silueta muy pequeña no es una foto de cuerpo completo.
  if (lastRow - firstRow < pixels.height * 0.3) return null;

  // El centro del cuerpo se toma de la cabeza, que casi siempre está centrada.
  final headRows = ((lastRow - firstRow) * 0.08).ceil().clamp(1, pixels.height);
  var centerSum = 0.0;
  var centerCount = 0;
  for (var y = firstRow; y < firstRow + headRows; y++) {
    for (final (left, right) in spansByRow[y]) {
      centerSum += (left + right) / 2;
      centerCount++;
    }
  }
  final center = centerSum / centerCount;

  final rows = <({double left, double right})?>[];
  for (final spans in spansByRow) {
    if (spans.isEmpty) {
      rows.add(null);
      continue;
    }
    rows.add(_centralSpan(spans, center, maxGap: pixels.width * 0.25, width: pixels.width));
  }

  return BodyShape(
    imageAspect: pixels.width / pixels.height,
    top: firstRow / pixels.height,
    bottom: (lastRow + 1) / pixels.height,
    rows: rows,
  );
}

/// Tramo de la fila que corresponde al cuerpo: el que contiene el centro. Si el
/// centro cae en un hueco angosto (entre las piernas), se unen los dos tramos
/// que lo rodean; si no, se usa el más cercano.
({double left, double right}) _centralSpan(
  List<(int, int)> spans,
  double center, {
  required double maxGap,
  required int width,
}) {
  (int, int)? leftOfCenter, rightOfCenter;
  for (final span in spans) {
    if (span.$1 <= center && center <= span.$2) {
      return (left: span.$1 / width, right: (span.$2 + 1) / width);
    }
    if (span.$2 < center) leftOfCenter = span;
    if (span.$1 > center && rightOfCenter == null) rightOfCenter = span;
  }
  if (leftOfCenter != null && rightOfCenter != null && rightOfCenter.$1 - leftOfCenter.$2 <= maxGap) {
    return (left: leftOfCenter.$1 / width, right: (rightOfCenter.$2 + 1) / width);
  }
  final nearest = [leftOfCenter, rightOfCenter].whereType<(int, int)>().reduce(
        (a, b) => (center - a.$2).abs() < (b.$1 - center).abs() ? a : b,
      );
  return (left: nearest.$1 / width, right: (nearest.$2 + 1) / width);
}

/// Dónde colocar una prenda: centro horizontal y borde superior como fracción
/// de la imagen del cuerpo, y ancho como fracción de su ancho.
class GarmentFit {
  final double centerX;
  final double top;
  final double width;

  const GarmentFit({required this.centerX, required this.top, required this.width});
}

/// Zona del cuerpo que cubre cada categoría (0 = cabeza, 1 = pies) y ancho
/// máximo en múltiplos del ancho de hombros. Proporciones aproximadas de una
/// persona de pie y de frente.
const _zones = {
  GarmentCategory.top: (start: 0.15, end: 0.50, maxShoulders: 2.4),
  GarmentCategory.outerwear: (start: 0.14, end: 0.60, maxShoulders: 2.6),
  GarmentCategory.dress: (start: 0.15, end: 0.78, maxShoulders: 2.4),
  GarmentCategory.bottom: (start: 0.43, end: 0.97, maxShoulders: 1.6),
  GarmentCategory.shoes: (start: 0.93, end: 1.0, maxShoulders: 1.4),
};

/// null si la categoría no tiene una zona fija (accesorios) o faltan medidas.
GarmentFit? fitGarment(GarmentCategory category, BodyShape body, GarmentShape garment) {
  final zone = _zones[category];
  final span = body.spanAt((zone?.start ?? 0) + ((zone?.end ?? 0) - (zone?.start ?? 0)) / 2);
  if (zone == null || span == null || body.shoulderWidth <= 0) return null;

  // Se trabaja en unidades del alto de la imagen para respetar la proporción.
  final targetHeight = (zone.end - zone.start) * body.height;
  final maxWidth = zone.maxShoulders * body.shoulderWidth * body.imageAspect;
  final width = (targetHeight / garment.aspect).clamp(0.0, maxWidth);
  return GarmentFit(
    centerX: (span.left + span.right) / 2,
    top: body.top + zone.start * body.height,
    width: width / body.imageAspect,
  );
}
