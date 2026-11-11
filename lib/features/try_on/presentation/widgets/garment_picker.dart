import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:closet_ai/features/closet/presentation/widgets/garment_card.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/dressing_room_controller.dart';
import 'package:closet_ai/features/closet/presentation/garment_labels.dart';

/// Horizontal strip with the closet's garments; tapping one puts it on.
class GarmentPicker extends ConsumerWidget {
  final ValueChanged<Garment> onPick;

  const GarmentPicker({super.key, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(closetProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('No se pudo cargar tu clóset: $error')),
          data: (garments) => garments.isEmpty
              ? const Center(child: Text('Agrega prendas en la pestaña Clóset.'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: garments.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _GarmentButton(garment: garments[index], onTap: onPick),
                ),
        );
  }
}

class _GarmentButton extends ConsumerWidget {
  final Garment garment;
  final ValueChanged<Garment> onTap;

  const _GarmentButton({required this.garment, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(dressingRoomProvider);
    final scheme = Theme.of(context).colorScheme;
    final worn = room.isWorn(garment.id);
    return Semantics(
      button: true,
      selected: worn,
      label: garment.displayName,
      child: GestureDetector(
        key: ValueKey('garment-${garment.id}'),
        onTap: () => onTap(garment),
        child: Container(
          width: 72,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: worn ? Border.all(color: scheme.primary, width: 2) : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GarmentTile(garment: garment),
              if (room.preparing.contains(garment.id))
                ColoredBox(
                  color: scheme.surface.withValues(alpha: 0.7),
                  child: const Center(
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
