import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/try_on/domain/try_on_layer.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/dressing_room_controller.dart';

/// Size slider and actions for the selected layer, or a hint when none is selected.
class LayerToolbar extends ConsumerWidget {
  const LayerToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(dressingRoomProvider);
    final controller = ref.read(dressingRoomProvider.notifier);
    final selected = room.selected;
    if (selected == null) {
      return Center(
        child: Text(
          room.layers.isEmpty ? 'Toca una prenda para ponértela' : 'Toca una prenda de la foto para ajustarla',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Row(
      children: [
        const Icon(Icons.photo_size_select_small, size: 18),
        Expanded(
          child: Slider(
            min: minLayerWidth,
            max: maxLayerWidth,
            value: selected.width,
            semanticFormatterCallback: (value) => 'Tamaño ${(value * 100).round()}%',
            onChanged: controller.resizeSelected,
          ),
        ),
        if (room.body != null && selected.shape != null)
          IconButton(
            tooltip: 'Ajustar automáticamente',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: controller.refitSelected,
          ),
        IconButton(
          tooltip: 'Quitar prenda',
          icon: const Icon(Icons.delete_outline),
          onPressed: controller.removeSelected,
        ),
      ],
    );
  }
}
