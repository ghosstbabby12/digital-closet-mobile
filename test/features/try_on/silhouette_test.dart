import 'dart:typed_data';

import 'package:closet_ai/features/try_on/domain/silhouette.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Transparent canvas to paint silhouettes on.
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

  /// A torso whose width changes between key rows: [(y, left, right)].
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

/// A 200x400 standing person: head with hair (y 15-75), neck (72-88),
/// 80 px shoulders at y=88, narrow waist, hips and crotch at y=210,
/// legs separated by a gap on the axis, and feet at y=385.
Canvas person({required bool handsOnHips}) {
  final c = Canvas(200, 400)
    ..ellipse(100, 45, 22, 30)
    ..rect(92, 72, 108, 88)
    ..torso([(88, 60, 140), (170, 75, 125), (210, 68, 132)])
    ..rect(72, 210, 98, 385)
    ..rect(102, 210, 128, 385);
  if (handsOnHips) {
    // Arms akimbo: away from the torso, with the hands on the waist.
    c
      ..rect(38, 96, 50, 172)
      ..rect(38, 165, 78, 178)
      ..rect(150, 96, 162, 172)
      ..rect(122, 165, 162, 178);
  } else {
    // Arms down against the body: they hang below the shoulders and only the
    // deltoids stick out a little.
    c
      ..rect(56, 90, 70, 250)
      ..rect(130, 90, 144, 250);
  }
  return c;
}

void main() {
  test('a garment is measured without its transparent borders', () {
    final shape = analyzeGarment((Canvas(200, 100)..rect(50, 10, 150, 60)).pixels)!;

    expect(shape.left, 0.25);
    expect(shape.right, 0.75);
    expect(shape.top, closeTo(0.1, 1e-9));
    expect(shape.bottom, closeTo(0.6, 1e-9));
    expect(shape.aspect, 0.5);
  });

  test('a fully transparent garment has no shape', () {
    expect(analyzeGarment(Canvas(10, 10).pixels), isNull);
  });

  test('a very small silhouette is not taken as a full body', () {
    expect(analyzeBody((Canvas(100, 200)..rect(40, 10, 60, 40)).pixels), isNull);
  });

  for (final handsOnHips in [false, true]) {
    group(handsOnHips ? 'con las manos en la cintura' : 'con los brazos caídos', () {
      late BodyShape body;
      setUp(() => body = analyzeBody(person(handsOnHips: handsOnHips).pixels)!);

      test('finds head, feet, shoulders and crotch', () {
        expect(body.top * 400, closeTo(15, 1));
        expect(body.bottom * 400, closeTo(385, 1));
        expect(body.shoulderY * 400, closeTo(88, 3));
        expect(body.crotchY * 400, closeTo(210, 4));
      });

      test('the body axis is the head\'s, not shifted by the arms', () {
        expect(body.centerX, closeTo(0.5, 0.01));
      });

      test('measures the shoulders without the arms', () {
        // Shoulders: 80 px of 200 (with the arms down some deltoid is added).
        expect(body.shoulderWidth * 200, closeTo(84, 6));
      });

      test('a blouse starts at the neck, centered and scaled by the shoulders', () {
        const blouse = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 0.8);

        final fit = fitGarment(GarmentCategory.top, body, blouse)!;

        expect(fit.centerX, closeTo(0.5, 0.01));
        expect(fit.top, closeTo(body.shoulderY - 0.03 * body.height, 1e-9));
        expect(fit.width, closeTo(body.shoulderWidth * 1.65, 1e-9));
        // It does not go below the hips.
        final bottom = fit.top + fit.width * body.imageAspect * blouse.aspect;
        expect(bottom, lessThanOrEqualTo(body.crotchY + 0.10 * body.height + 1e-9));
      });

      test('a very long jacket is shortened above the knee', () {
        const coat = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 4);

        final fit = fitGarment(GarmentCategory.outerwear, body, coat)!;

        final bottom = fit.top + fit.width * body.imageAspect * coat.aspect;
        expect(bottom, closeTo(body.top + 0.78 * body.height, 1e-9));
      });

      test('pants go from the waist to the ankles', () {
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

  test('shoes rest on the feet even when they are not under the head', () {
    // Same person, but with the feet shifted right (weight on one leg).
    final c = Canvas(200, 400)
      ..ellipse(100, 45, 22, 30)
      ..rect(92, 72, 108, 88)
      ..torso([(88, 60, 140), (170, 75, 125), (210, 68, 132)])
      ..rect(72, 210, 98, 360)
      ..rect(102, 210, 128, 360)
      ..rect(100, 360, 150, 385);
    final body = analyzeBody(c.pixels)!;
    const shoes = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 0.5);

    final fit = fitGarment(GarmentCategory.shoes, body, shoes)!;

    expect(body.feetCenterX * 200, closeTo(125, 2));
    expect(fit.centerX, closeTo(body.feetCenterX, 1e-9));
    final bottom = fit.top + fit.width * body.imageAspect * shoes.aspect;
    expect(bottom, closeTo(body.bottom, 1e-9));
    // Wider than the feet, but not too much.
    expect(fit.width, greaterThan(body.feetWidth));
    expect(fit.width, lessThan(body.feetWidth * 1.3));
  });

  test('tall boots shrink so they do not climb up the leg', () {
    final body = analyzeBody(person(handsOnHips: false).pixels)!;
    const boots = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 3);

    final fit = fitGarment(GarmentCategory.shoes, body, boots)!;

    expect(fit.width * body.imageAspect * boots.aspect, closeTo(0.09 * body.height, 1e-9));
  });

  test('accessories have no fixed area', () {
    final body = analyzeBody(person(handsOnHips: false).pixels)!;
    const bag = GarmentShape(left: 0, top: 0, right: 1, bottom: 1, aspect: 1);

    expect(fitGarment(GarmentCategory.accessory, body, bag), isNull);
  });

  test('dresses in order: pants, blouse and the jacket on top', () {
    expect(layerOrder(GarmentCategory.bottom), lessThan(layerOrder(GarmentCategory.top)));
    expect(layerOrder(GarmentCategory.top), lessThan(layerOrder(GarmentCategory.outerwear)));
  });
}
