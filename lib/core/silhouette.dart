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

/// Silueta de una persona de pie y de frente, medida en su foto recortada.
/// Las alturas son fracciones del alto de la imagen y los anchos y posiciones
/// horizontales, fracciones de su ancho.
class BodyShape {
  /// Ancho / alto de la imagen.
  final double imageAspect;

  /// Coronilla y planta de los pies.
  final double top;
  final double bottom;

  /// Eje vertical del cuerpo, tomado del centro de la cabeza.
  final double centerX;

  /// Línea de los hombros y de la entrepierna.
  final double shoulderY;
  final double crotchY;

  /// Ancho de los hombros y de la cadera.
  final double shoulderWidth;
  final double hipWidth;

  const BodyShape({
    required this.imageAspect,
    required this.top,
    required this.bottom,
    required this.centerX,
    required this.shoulderY,
    required this.crotchY,
    required this.shoulderWidth,
    required this.hipWidth,
  });

  double get height => bottom - top;

  /// Altura de la pretina de un pantalón de tiro medio: entre la cintura y la cadera.
  double get waistY => shoulderY + 0.65 * (crotchY - shoulderY);
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
  final height = lastRow - firstRow + 1;
  // Una silueta muy pequeña no es una foto de cuerpo completo.
  if (height < pixels.height * 0.3) return null;
  int rowAt(double bodyFraction) => (firstRow! + bodyFraction * height).round().clamp(firstRow, lastRow!);

  // El eje del cuerpo se toma de la cabeza, que casi siempre está centrada;
  // los brazos (por ejemplo, las manos en la cintura) no lo desplazan.
  var centerSum = 0.0;
  var centerCount = 0;
  for (var y = firstRow; y <= rowAt(0.06); y++) {
    for (final (left, right) in spansByRow[y]) {
      centerSum += (left + right) / 2;
      centerCount++;
    }
  }
  final center = centerSum / centerCount;

  final rows = [for (final spans in spansByRow) _centralSpan(spans, center, maxGap: pixels.width * 0.25)];
  int widthAt(int y) => rows[y] == null ? 0 : rows[y]!.$2 - rows[y]!.$1 + 1;

  // Cuello: la fila más angosta entre la cabeza y los hombros.
  var neckRow = rowAt(0.08);
  for (var y = rowAt(0.08); y <= rowAt(0.25); y++) {
    if (widthAt(y) > 0 && widthAt(y) < widthAt(neckRow)) neckRow = y;
  }
  var headWidth = 0;
  for (var y = firstRow; y < neckRow; y++) {
    if (widthAt(y) > headWidth) headWidth = widthAt(y);
  }

  // Hombros: donde el cuerpo se ensancha claramente después del cuello.
  var shoulderRow = rowAt(0.18);
  for (var y = neckRow; y <= rowAt(0.32); y++) {
    if (widthAt(y) >= widthAt(neckRow) * 2.2) {
      shoulderRow = y;
      break;
    }
  }

  // Entrepierna: se sube desde los tobillos mientras el eje del cuerpo siga
  // cayendo en el hueco entre las piernas. Se toleran cortes de pocas filas,
  // que en una foto real son ruido del recorte (rodillas juntas, sombras).
  var crotchRow = rowAt(0.5);
  final ankleRow = rowAt(0.92);
  if (_centerInGap(spansByRow[ankleRow], center)) {
    final maxBreak = (height * 0.015).ceil();
    var breakRows = 0;
    for (var y = ankleRow; y >= rowAt(0.38); y--) {
      if (_centerInGap(spansByRow[y], center)) {
        crotchRow = y;
        breakRows = 0;
      } else if (++breakRows > maxBreak) {
        break;
      }
    }
  }

  // Si los brazos van pegados al cuerpo, el ancho medido los incluye: se acota
  // con el ancho de la cabeza, que guarda una proporción estable con los hombros.
  // Se mide justo bajo la línea de los hombros, antes de que se separen los brazos.
  final measuredShoulders = widthAt(shoulderRow + (height * 0.01).round());
  final shoulders = headWidth > 0
      ? measuredShoulders.clamp((headWidth * 1.5).round(), (headWidth * 2.6).round())
      : measuredShoulders;
  final hips = widthAt(crotchRow - (height * 0.03).round());

  return BodyShape(
    imageAspect: pixels.width / pixels.height,
    top: firstRow / pixels.height,
    bottom: (lastRow + 1) / pixels.height,
    centerX: (center + 0.5) / pixels.width,
    shoulderY: shoulderRow / pixels.height,
    crotchY: crotchRow / pixels.height,
    shoulderWidth: shoulders / pixels.width,
    hipWidth: (hips > 0 ? hips : shoulders) / pixels.width,
  );
}

bool _centerInGap(List<(int, int)> spans, double center) =>
    spans.isNotEmpty && !spans.any((span) => span.$1 <= center && center <= span.$2);

/// Tramo de la fila que corresponde al cuerpo: el que contiene el eje. Si el
/// eje cae en un hueco angosto (entre las piernas), se unen los dos tramos que
/// lo rodean; si no, se usa el más cercano.
(int, int)? _centralSpan(List<(int, int)> spans, double center, {required double maxGap}) {
  if (spans.isEmpty) return null;
  (int, int)? leftOfCenter, rightOfCenter;
  for (final span in spans) {
    if (span.$1 <= center && center <= span.$2) return span;
    if (span.$2 < center) leftOfCenter = span;
    if (span.$1 > center && rightOfCenter == null) rightOfCenter = span;
  }
  if (leftOfCenter != null && rightOfCenter != null && rightOfCenter.$1 - leftOfCenter.$2 <= maxGap) {
    return (leftOfCenter.$1, rightOfCenter.$2);
  }
  return [leftOfCenter, rightOfCenter].whereType<(int, int)>().reduce(
        (a, b) => (center - a.$2).abs() < (b.$1 - center).abs() ? a : b,
      );
}

/// Dónde colocar una prenda: centro horizontal y borde superior como fracción
/// de la imagen del cuerpo, y ancho como fracción de su ancho.
class GarmentFit {
  final double centerX;
  final double top;
  final double width;

  const GarmentFit({required this.centerX, required this.top, required this.width});
}

/// Orden de vestir, de abajo hacia arriba: el pantalón bajo la blusa y la chaqueta encima.
int layerOrder(GarmentCategory category) => switch (category) {
      GarmentCategory.bottom => 0,
      GarmentCategory.shoes => 1,
      GarmentCategory.dress => 2,
      GarmentCategory.top => 3,
      GarmentCategory.outerwear => 4,
      GarmentCategory.accessory => 5,
    };

/// null si la categoría no tiene una zona fija (accesorios).
GarmentFit? fitGarment(GarmentCategory category, BodyShape body, GarmentShape garment) {
  // Se trabaja en unidades del alto de la imagen para respetar la proporción.
  final aspect = body.imageAspect;
  final shoulders = body.shoulderWidth * aspect;
  final hips = body.hipWidth * aspect;
  final collar = body.shoulderY - 0.03 * body.height;

  // Las prendas de arriba se escalan por los hombros: en la foto de la prenda,
  // la costura de los hombros ocupa cerca del 60 % del ancho (las mangas, el resto).
  // El largo se limita para que no pasen de donde terminaría la prenda.
  GarmentFit upper({required double widthFactor, required double maxBottom}) {
    var width = shoulders * widthFactor;
    final maxHeight = maxBottom - collar;
    if (width * garment.aspect > maxHeight) width = maxHeight / garment.aspect;
    return GarmentFit(centerX: body.centerX, top: collar, width: width / aspect);
  }

  switch (category) {
    case GarmentCategory.top:
      return upper(widthFactor: 1.65, maxBottom: body.crotchY + 0.10 * body.height);
    case GarmentCategory.outerwear:
      return upper(widthFactor: 1.75, maxBottom: body.top + 0.78 * body.height);
    case GarmentCategory.dress:
      return upper(widthFactor: 1.5, maxBottom: body.bottom);
    case GarmentCategory.bottom:
      // El pantalón se escala por el largo de las piernas, de la cintura al tobillo.
      final top = body.waistY;
      final length = body.bottom - 0.02 * body.height - top;
      final width = (length / garment.aspect).clamp(0.0, hips * 1.6);
      return GarmentFit(centerX: body.centerX, top: top, width: width / aspect);
    case GarmentCategory.shoes:
      final height = 0.07 * body.height;
      final width = (height / garment.aspect).clamp(0.0, hips * 1.3);
      return GarmentFit(
        centerX: body.centerX,
        top: body.bottom - width * garment.aspect,
        width: width / aspect,
      );
    case GarmentCategory.accessory:
      return null;
  }
}
