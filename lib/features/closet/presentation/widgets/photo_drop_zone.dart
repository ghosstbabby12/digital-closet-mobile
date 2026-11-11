import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Box that shows the chosen photo, or an invitation to take or pick one.
class PhotoDropZone extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const PhotoDropZone({super.key, required this.imageBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
        child: imageBytes == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 36, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    const Text('Toca para tomar o elegir una foto'),
                  ],
                ),
              )
            : Image.memory(imageBytes!, fit: BoxFit.contain, width: double.infinity),
      ),
    );
  }
}
