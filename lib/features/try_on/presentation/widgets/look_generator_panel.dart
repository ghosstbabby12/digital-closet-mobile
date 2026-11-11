import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/widgets/primary_button.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/dressing_room_controller.dart';

/// "Ver cómo me queda" button with a caption about the AI service.
class LookGeneratorPanel extends ConsumerWidget {
  final VoidCallback onGenerate;

  const LookGeneratorPanel({super.key, required this.onGenerate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(dressingRoomProvider);
    final caption = room.generating
        ? 'Probando ${room.aiLayers.length} prenda(s), una tras otra: unos 10 segundos por prenda.'
        : [
            'El servicio FASHN recibe tu foto y estas prendas y dibuja el look; tarda unos segundos por prenda.',
            if (room.hasLayersAiSkips) 'Los accesorios no se incluyen.',
          ].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: room.generating ? 'Creando tu look...' : 'Ver cómo me queda',
          loading: room.generating,
          onPressed: onGenerate,
        ),
        const SizedBox(height: 4),
        Text(caption, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
