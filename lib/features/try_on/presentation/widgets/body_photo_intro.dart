import 'package:flutter/material.dart';

import 'package:closet_ai/core/theme/app_theme.dart';
import 'package:closet_ai/core/widgets/primary_button.dart';

/// Shown until the user uploads a full-body photo.
class BodyPhotoIntro extends StatelessWidget {
  final bool uploading;
  final VoidCallback onUpload;

  const BodyPhotoIntro({super.key, required this.uploading, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, floatingNavClearance),
      children: [
        Text('Pruébate tu clóset', style: textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Sube una foto tuya de cuerpo completo y coloca tus prendas encima para ver cómo combinan.',
          style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Para un mejor resultado', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  '• De frente, de la cabeza a los pies\n• Con ropa ajustada y buena luz\n• Con un fondo sencillo',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 20, color: scheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Para quitar el fondo, tu foto se envía a remove.bg, un servicio externo. '
                    'Guardamos solo el recorte, en privado, y puedes eliminarlo cuando quieras.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Subir mi foto', loading: uploading, onPressed: onUpload),
      ],
    );
  }
}
