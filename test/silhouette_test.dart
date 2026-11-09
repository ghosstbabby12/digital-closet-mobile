import 'dart:typed_data';

import 'package:closet_ai/core/silhouette.dart';
import 'package:closet_ai/models/garment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lienzo transparente sobre el que se pintan siluetas.
class Canvas {
  Canvas(this.width, this.height) : data = Uint8List(width * height * 4);
  final int width;
  final int height;
  final Uint8List data;

  void dot(int x, int y) {
    if (x >= 0 && x < width && y >= 0 && y < height) data[(y * width + x) * 4 + 3] = 255;
  }

  void rect(int x0, int y0, int x1, int y1) {
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        dot(x, y);
      }
    }
  }

  void ellipse(double cx, double cy, double rx, double ry) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final dx = (x - cx) / rx, dy = (y - cy) / ry;
        if (dx * dx + dy * dy <= 1) dot(x, y);
      }
    }
  }

  /// Tronco que cambia de ancho entre filas clave: [(y, izquierda, derecha)].
  void torso(List<(int, int, int)> keys) {
    for (var i = 0; i < keys.length - 1; i++) {
      final (y0, l0, r0) = keys[i];
      final (y1, l1, r1) = keys[i + 1];
      for (var y = y0; y < y1; y++) {
        final t = (y - y0) / (y1 - y0);
        rect((l0 + (l1 - l0) * t).round(), y, (r0 + (r1 - r0) * t).round(), y + 1);
      }
    }
  }

  RgbaPixels get pixels => RgbaPixels(data, width, height);
}

/// Persona de 200x400 de pie: cabeza con pelo (y 15-75), cuello (72-88),
/// hombros de 80 px en y=88, cintura angosta, cadera y entrepierna en y=210,
/// piernas separadas por un hueco en el eje y pies en y=385.
Canvas person({required bool handsOnHips}) {
  final c = Canvas(200, 400)
    ..ellipse(100, 45, 22, 30)
    ..rect(92, 72, 108, 88)
    ..torso([(88, 60, 140), (170, 75, 125), (210, 68, 132)])
    ..rect(72, 210, 98, 385)
    ..rect(102, 210, 128, 385);
  if (handsOnHips) {
    // Brazos en jarra: separados del torso y con las manos en la cintura.
    c
      ..rect(38, 96, 50, 172)
      ..rect(38, 165, 78, 178)
      ..rect(150, 96, 162, 172)
      ..rect(122, 165, 162, 178);
  } else {
    // Brazos caídos y pegados al cuerpo: cuelgan bajo los hombros y solo el
    // deltoides sobresale un poco.
    c
      ..rect(56, 90, 70, 250)
      ..rect(130, 90, 144, 250);
  }
  return c;
}

void main() {
  test('la prenda se mide sin sus bordes transparentes', () {
    final shape = analyzeGarment((Canvas(200, 100)..rect(50, 10, 150, 60)).pixels)!;

    expect(shape.left, 0.25);
    expect(shape.right, 0.75);
    expect(shape.top, closeTo(0.1, 1e-9));
    expect(shape.bottom, closeTo(0.6, 1e-9));
    expect(shape.aspect, 0.5);
  });

  test('una prenda totalmente transparente no tiene forma', () {
    expect(analyzeGarment(Canvas(10, 10).pixels), isNull);
  });

  test('una silueta muy pequeña no se toma como cuerpo completo', () {
    expect(analyzeBody((Canvas(100, 200)..rect(40, 10, 60, 40)).pixels), isNull);
  });

  for (final handsOnHips in [false, true]) {
    group(handsOnHips ? 'con las manos en la cintura' : 'con los brazos caídos', () {
      late BodyShape body;
      setUp(() => body = analyzeBody(person(handsOnHips: handsOnHips).pixels)!);

      test('encuentra cabeza, pies, hombros y entrepierna', () {
        expect(body.top * 400, closeTo(15, 1));
        expect(body.bottom * 400, closeTo(385, 1));
        expect(body.shoulderY * 400, closeTo(88, 3));
        expect(body.crotchY * 400, closeTo(210, 4));
      });

      test('el eje del cuerpo es el de la cabeza, sin desviarse por los brazos', () {
        expect(body.centerX, closeTo(0.5, 0.01));
      });

      test('mide los hombros sin sumar los brazos', () {
        // Hombros: 80 px de 200 (con los brazos pegados se suma algo del deltoides).
        expect(body.shoulderWidth * 200, closeTo(84, 6));
      });

      test('la blusa empieza en el cuello, centrada y escalada por los hombros', () {
        const blouse = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 0.8);

        final fit = fitGarment(GarmentCategory.top, body, blouse)!;

        expect(fit.centerX, closeTo(0.5, 0.01));
        expect(fit.top, closeTo(body.shoulderY - 0.03 * body.height, 1e-9));
        expect(fit.width, closeTo(body.shoulderWidth * 1.65, 1e-9));
        // No baja más allá de la cadera.
        final bottom = fit.top + fit.width * body.imageAspect * blouse.aspect;
        expect(bottom, lessThanOrEqualTo(body.crotchY + 0.10 * body.height + 1e-9));
      });

      test('una chaqueta muy larga se acorta por encima de la rodilla', () {
        const coat = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 4);

        final fit = fitGarment(GarmentCategory.outerwear, body, coat)!;

        final bottom = fit.top + fit.width * body.imageAspect * coat.aspect;
        expect(bottom, closeTo(body.top + 0.78 * body.height, 1e-9));
      });

      test('el pantalón va de la cintura a los tobillos', () {
        const pants = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 3);

        final fit = fitGarment(GarmentCategory.bottom, body, pants)!;

        expect(fit.top, greaterThan(body.shoulderY));
        expect(fit.top, lessThan(body.crotchY));
        expect(fit.centerX, closeTo(0.5, 0.01));
        final bottom = fit.top + fit.width * body.imageAspect * pants.aspect;
        expect(bottom, closeTo(body.bottom - 0.02 * body.height, 1e-6));
      });
    });
  }

  test('los accesorios no tienen una zona fija', () {
    final body = analyzeBody(person(handsOnHips: false).pixels)!;
    const bag = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 1);

    expect(fitGarment(GarmentCategory.accessory, body, bag), isNull);
  });

  test('se viste en orden: pantalón, blusa y chaqueta encima', () {
    expect(layerOrder(GarmentCategory.bottom), lessThan(layerOrder(GarmentCategory.top)));
    expect(layerOrder(GarmentCategory.top), lessThan(layerOrder(GarmentCategory.outerwear)));
  });
}
