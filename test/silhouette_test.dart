import 'dart:typed_data';

import 'package:closet_ai/core/silhouette.dart';
import 'package:closet_ai/models/garment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Imagen transparente con rectángulos opacos [x0, y0, x1, y1).
RgbaPixels canvas(int width, int height, List<(int, int, int, int)> boxes) {
  final data = Uint8List(width * height * 4);
  for (final (x0, y0, x1, y1) in boxes) {
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        data[(y * width + x) * 4 + 3] = 255;
      }
    }
  }
  return RgbaPixels(data, width, height);
}

/// Silueta de 100x200: cabeza, torso con brazos separados y dos piernas.
RgbaPixels person() => canvas(100, 200, [
      (40, 10, 60, 30), // cabeza
      (30, 40, 70, 110), // torso (hombros de 40 px)
      (20, 40, 26, 100), // brazo izquierdo, separado del torso
      (74, 40, 80, 100), // brazo derecho
      (32, 110, 48, 190), // pierna izquierda
      (52, 110, 68, 190), // pierna derecha
    ]);

void main() {
  test('la prenda se mide sin sus bordes transparentes', () {
    final shape = analyzeGarment(canvas(200, 100, [(50, 10, 150, 60)]))!;

    expect(shape.left, 0.25);
    expect(shape.right, 0.75);
    expect(shape.top, closeTo(0.1, 1e-9));
    expect(shape.bottom, closeTo(0.6, 1e-9));
    expect(shape.aspect, 0.5);
  });

  test('una prenda totalmente transparente no tiene forma', () {
    expect(analyzeGarment(canvas(10, 10, [])), isNull);
  });

  test('encuentra cabeza, pies y hombros sin contar los brazos separados', () {
    final body = analyzeBody(person())!;

    expect(body.top, 10 / 200);
    expect(body.bottom, 190 / 200);
    expect(body.shoulderWidth, closeTo(0.4, 1e-9));
    final waist = body.spanAt(0.5)!;
    expect((waist.left + waist.right) / 2, closeTo(0.5, 1e-9));
  });

  test('entre las piernas toma las dos juntas y no solo una', () {
    final body = analyzeBody(person())!;

    final legs = body.spanAt(0.7)!;

    expect(legs.left, closeTo(0.32, 1e-9));
    expect(legs.right, closeTo(0.68, 1e-9));
  });

  test('una silueta muy pequeña no se toma como cuerpo completo', () {
    expect(analyzeBody(canvas(100, 200, [(40, 10, 60, 40)])), isNull);
  });

  test('el pantalón va de la cintura a los tobillos, centrado', () {
    final body = analyzeBody(person())!;
    // Pantalón recortado mucho más alto que ancho.
    final pants = analyzeGarment(canvas(100, 300, [(20, 0, 80, 300)]))!;

    final fit = fitGarment(GarmentCategory.bottom, body, pants)!;

    expect(fit.top, closeTo(body.top + 0.43 * body.height, 1e-9));
    expect(fit.centerX, closeTo(0.5, 1e-9));
    // Alto de la zona (0.54 del cuerpo) a la proporción del pantalón (5:1).
    final expectedWidth = (0.54 * body.height / 5) / body.imageAspect;
    expect(fit.width, closeTo(expectedWidth, 1e-9));
  });

  test('una prenda muy ancha se limita al ancho de los hombros', () {
    final body = analyzeBody(person())!;
    // Suéter extendido, mucho más ancho que alto.
    final sweater = analyzeGarment(canvas(400, 100, [(0, 0, 400, 100)]))!;

    final fit = fitGarment(GarmentCategory.top, body, sweater)!;

    expect(fit.width, closeTo(2.4 * body.shoulderWidth, 1e-9));
  });

  test('los accesorios no tienen una zona fija', () {
    final body = analyzeBody(person())!;
    final bag = analyzeGarment(canvas(10, 10, [(0, 0, 10, 10)]))!;

    expect(fitGarment(GarmentCategory.accessory, body, bag), isNull);
  });
}
