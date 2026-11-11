import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet to take a photo, pick one from the gallery or (optionally) remove the current one.
void showPhotoSourceSheet(
  BuildContext context, {
  required ValueChanged<ImageSource> onPick,
  VoidCallback? onRemove,
  String removeLabel = 'Eliminar foto',
}) {
  final error = Theme.of(context).colorScheme.error;
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      void choose(VoidCallback action) {
        Navigator.pop(sheetContext);
        action();
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => choose(() => onPick(ImageSource.camera)),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => choose(() => onPick(ImageSource.gallery)),
            ),
            if (onRemove != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: error),
                title: Text(removeLabel, style: TextStyle(color: error)),
                onTap: () => choose(onRemove),
              ),
          ],
        ),
      );
    },
  );
}
