import 'dart:typed_data';

import 'package:closet_ai/features/closet/domain/garment.dart';

/// RGBA pixels of an image (4 bytes per pixel, not premultiplied).
class RgbaPixels {
  final Uint8List data;
  final int width;
  final int height;

  const RgbaPixels(this.data, this.width, this.height);

  int alphaAt(int x, int y) => data[(y * width + x) * 4 + 3];
}

/// Visible area of a garment cutout, without the transparent borders.
/// Positions are fractions of the image size.
class GarmentShape {
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Height / width of the visible area, in real pixels.
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

/// Silhouette of a person standing, facing the camera, measured on their cutout photo.
/// Heights are fractions of the image height; widths and horizontal
/// positions are fractions of its width.
class BodyShape {
  /// Image width / height.
  final double imageAspect;

  /// Top of the head and soles of the feet.
  final double top;
  final double bottom;

  /// Vertical axis of the body, taken from the center of the head.
  final double centerX;

  /// Shoulder line and crotch line.
  final double shoulderY;
  final double crotchY;

  /// Shoulder and hip width.
  final double shoulderWidth;
  final double hipWidth;

  /// Center and width of both feet, measured in the lowest band of the
  /// silhouette: they are not always under the head (crossed feet, weight on one leg).
  final double feetCenterX;
  final double feetWidth;

  const BodyShape({
    required this.imageAspect,
    required this.top,
    required this.bottom,
    required this.centerX,
    required this.shoulderY,
    required this.crotchY,
    required this.shoulderWidth,
    required this.hipWidth,
    required this.feetCenterX,
    required this.feetWidth,
  });

  double get height => bottom - top;

  /// Waistband height of mid-rise pants: between the waist and the hips.
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
  // A very small silhouette is not a full-body photo.
  if (height < pixels.height * 0.3) return null;
  int rowAt(double bodyFraction) => (firstRow! + bodyFraction * height).round().clamp(firstRow, lastRow!);

  // The body axis comes from the head, which is almost always centered;
  // the arms (for example, hands on the hips) do not shift it.
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

  // Neck: the narrowest row between the head and the shoulders.
  var neckRow = rowAt(0.08);
  for (var y = rowAt(0.08); y <= rowAt(0.25); y++) {
    if (widthAt(y) > 0 && widthAt(y) < widthAt(neckRow)) neckRow = y;
  }
  var headWidth = 0;
  for (var y = firstRow; y < neckRow; y++) {
    if (widthAt(y) > headWidth) headWidth = widthAt(y);
  }

  // Shoulders: where the body clearly widens after the neck.
  var shoulderRow = rowAt(0.18);
  for (var y = neckRow; y <= rowAt(0.32); y++) {
    if (widthAt(y) >= widthAt(neckRow) * 2.2) {
      shoulderRow = y;
      break;
    }
  }

  // Crotch: walk up from the ankles while the body axis still
  // falls in the gap between the legs. Breaks of a few rows are tolerated,
  // since in a real photo they are cutout noise (knees together, shadows).
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

  // With the arms against the body the measured width includes them, so it is
  // bounded by the head width, which keeps a stable ratio to the shoulders.
  // Measured just below the shoulder line, before the arms separate.
  final measuredShoulders = widthAt(shoulderRow + (height * 0.01).round());
  final shoulders = headWidth > 0
      ? measuredShoulders.clamp((headWidth * 1.5).round(), (headWidth * 2.6).round())
      : measuredShoulders;
  final hips = widthAt(crotchRow - (height * 0.03).round());

  // Feet: the body span in the last 5 % of the height.
  var feetLeft = pixels.width, feetRight = -1;
  for (var y = rowAt(0.95); y <= lastRow; y++) {
    final span = rows[y];
    if (span == null) continue;
    if (span.$1 < feetLeft) feetLeft = span.$1;
    if (span.$2 > feetRight) feetRight = span.$2;
  }
  final hasFeet = feetRight >= feetLeft;

  return BodyShape(
    imageAspect: pixels.width / pixels.height,
    top: firstRow / pixels.height,
    bottom: (lastRow + 1) / pixels.height,
    centerX: (center + 0.5) / pixels.width,
    shoulderY: shoulderRow / pixels.height,
    crotchY: crotchRow / pixels.height,
    shoulderWidth: shoulders / pixels.width,
    hipWidth: (hips > 0 ? hips : shoulders) / pixels.width,
    feetCenterX: hasFeet ? (feetLeft + feetRight + 1) / 2 / pixels.width : (center + 0.5) / pixels.width,
    feetWidth: hasFeet ? (feetRight - feetLeft + 1) / pixels.width : (hips > 0 ? hips : shoulders) * 0.6 / pixels.width,
  );
}

bool _centerInGap(List<(int, int)> spans, double center) =>
    spans.isNotEmpty && !spans.any((span) => span.$1 <= center && center <= span.$2);

/// The span of the row that belongs to the body: the one holding the axis. If the
/// axis falls in a narrow gap (between the legs), the two spans around it are
/// joined; otherwise the closest one is used.
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
  return [
    leftOfCenter,
    rightOfCenter,
  ].whereType<(int, int)>().reduce((a, b) => (center - a.$2).abs() < (b.$1 - center).abs() ? a : b);
}

/// Where to place a garment: horizontal center and top edge as fractions
/// of the body image, and width as a fraction of its width.
class GarmentFit {
  final double centerX;
  final double top;
  final double width;

  const GarmentFit({required this.centerX, required this.top, required this.width});
}

/// Wearing order, bottom to top: pants under the blouse and the jacket on top.
int layerOrder(GarmentCategory category) => switch (category) {
  GarmentCategory.bottom => 0,
  GarmentCategory.shoes => 1,
  GarmentCategory.dress => 2,
  GarmentCategory.top => 3,
  GarmentCategory.outerwear => 4,
  GarmentCategory.accessory => 5,
};

/// null when the category has no fixed area (accessories).
GarmentFit? fitGarment(GarmentCategory category, BodyShape body, GarmentShape garment) {
  // Works in image-height units to keep the aspect ratio.
  final aspect = body.imageAspect;
  final shoulders = body.shoulderWidth * aspect;
  final hips = body.hipWidth * aspect;
  final collar = body.shoulderY - 0.03 * body.height;

  // Upper garments scale with the shoulders: in the garment photo,
  // the shoulder seam takes about 60 % of the width (the sleeves, the rest).
  // The length is capped so they do not go past where the garment would end.
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
      // Pants scale with the leg length, from the waist to the ankle.
      final top = body.waistY;
      final length = body.bottom - 0.02 * body.height - top;
      final width = (length / garment.aspect).clamp(0.0, hips * 1.6);
      return GarmentFit(centerX: body.centerX, top: top, width: width / aspect);
    case GarmentCategory.shoes:
      // A pair of shoes scales with the feet width, a little
      // looser, and rests on the soles; it cannot be taller than an ankle boot.
      final feet = body.feetWidth * aspect;
      var width = (feet * 1.15).clamp(hips * 0.45, hips * 1.3);
      final maxHeight = 0.09 * body.height;
      if (width * garment.aspect > maxHeight) width = maxHeight / garment.aspect;
      return GarmentFit(centerX: body.feetCenterX, top: body.bottom - width * garment.aspect, width: width / aspect);
    case GarmentCategory.accessory:
      return null;
  }
}
