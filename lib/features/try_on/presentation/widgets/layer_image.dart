import 'package:flutter/material.dart';

import 'package:closet_ai/core/network/image_url.dart';
import 'package:closet_ai/features/try_on/domain/try_on_layer.dart';

/// The garment cutout. Once measured, only its visible area is shown, without empty borders.
class LayerImage extends StatelessWidget {
  final TryOnLayer layer;
  final double width;

  const LayerImage({super.key, required this.layer, required this.width});

  @override
  Widget build(BuildContext context) {
    final url = fullImageUrl(layer.garment.cutoutUrl!);
    Widget broken(BuildContext context, Object error, StackTrace? stackTrace) => SizedBox(
      height: width,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
    final shape = layer.shape;
    if (shape == null) return Image.network(url, fit: BoxFit.fitWidth, errorBuilder: broken);

    final height = width * shape.aspect;
    final fullWidth = width / (shape.right - shape.left);
    final fullHeight = height / (shape.bottom - shape.top);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: fullWidth,
          maxWidth: fullWidth,
          minHeight: fullHeight,
          maxHeight: fullHeight,
          child: Transform.translate(
            offset: Offset(-shape.left * fullWidth, -shape.top * fullHeight),
            child: Image.network(url, fit: BoxFit.fill, errorBuilder: broken),
          ),
        ),
      ),
    );
  }
}
