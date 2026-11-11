import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/network/image_url.dart';
import 'package:closet_ai/core/widgets/retry_message.dart';
import 'package:closet_ai/features/try_on/domain/try_on_layer.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/dressing_room_controller.dart';
import 'package:closet_ai/features/closet/presentation/garment_labels.dart';
import 'package:closet_ai/features/try_on/presentation/widgets/layer_image.dart';

/// The body photo with the garment layers on top. Drag to move a layer, pinch to resize it.
class TryOnStage extends ConsumerStatefulWidget {
  final String photoUrl;
  final bool busy;
  final VoidCallback onPhotoError;

  const TryOnStage({super.key, required this.photoUrl, required this.busy, required this.onPhotoError});

  @override
  ConsumerState<TryOnStage> createState() => _TryOnStageState();
}

class _TryOnStageState extends ConsumerState<TryOnStage> {
  double _gestureStartWidth = 0;

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(dressingRoomProvider);
    final controller = ref.read(dressingRoomProvider.notifier);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stage = constraints.biggest;
            controller.setStageSize(stage);
            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.deselect,
                  child: Image.network(
                    fullImageUrl(widget.photoUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        RetryMessage(message: 'No se pudo mostrar tu foto.', onRetry: widget.onPhotoError),
                  ),
                ),
                for (final layer in room.wearingOrder) _layer(layer, stage, layer.garmentId == room.selectedId),
                if (widget.busy) const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _layer(TryOnLayer layer, Size stage, bool selected) {
    final controller = ref.read(dressingRoomProvider.notifier);
    final width = layer.width * stage.width;
    return Positioned(
      left: layer.centerX * stage.width - width / 2,
      top: layer.top * stage.height,
      width: width,
      child: Semantics(
        label: layer.garment.displayName,
        button: true,
        selected: selected,
        child: GestureDetector(
          key: ValueKey('layer-${layer.garmentId}'),
          onTap: () => controller.select(layer.garmentId),
          onScaleStart: (_) {
            if (!selected) controller.select(layer.garmentId);
            _gestureStartWidth = layer.width;
          },
          onScaleUpdate: (details) => controller.moveSelected(
            details.focalPointDelta.dx / stage.width,
            details.focalPointDelta.dy / stage.height,
            width: details.pointerCount > 1 ? _gestureStartWidth * details.scale : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayerImage(layer: layer, width: width),
          ),
        ),
      ),
    );
  }
}
