import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:closet_ai/features/closet/presentation/garment_labels.dart';
import 'package:closet_ai/features/closet/presentation/screens/garment_detail_screen.dart';
import 'package:closet_ai/features/closet/presentation/widgets/empty_closet_card.dart';
import 'package:closet_ai/features/closet/presentation/widgets/garment_card.dart';
import 'package:closet_ai/features/outfits/domain/closet_highlights.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:closet_ai/features/outfits/presentation/controllers/outfit_controller.dart';

const _titles = {
  HighlightKind.forgotten: 'Lo que no te has puesto últimamente',
  HighlightKind.lastOutfit: 'Tu último outfit',
  HighlightKind.closet: 'En tu clóset',
};
const _slots = 4;

/// Garments from the closet under the stylist button; dimmed while an outfit is being made.
class ClosetHighlightsCard extends ConsumerWidget {
  final bool generating;

  const ClosetHighlightsCard({super.key, required this.generating});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(outfitHistoryProvider).valueOrNull ?? const <Outfit>[];
    return ref
        .watch(closetProvider)
        .when(
          loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('No pudimos cargar tu clóset.'),
              trailing: TextButton(
                onPressed: () => ref.read(closetProvider.notifier).load(),
                child: const Text('Reintentar'),
              ),
            ),
          ),
          data: (closet) {
            if (closet.isEmpty) return const EmptyClosetCard();
            final highlights = pickHighlights(closet, history, now: DateTime.now(), max: _slots);
            return _HighlightsCard(
              title: generating ? 'Combinando tus prendas...' : _titles[highlights.kind]!,
              garments: highlights.garments,
              generating: generating,
            );
          },
        );
  }
}

class _HighlightsCard extends StatelessWidget {
  final String title;
  final List<Garment> garments;
  final bool generating;

  const _HighlightsCard({required this.title, required this.garments, required this.generating});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < _slots; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: i < garments.length
                        ? _HighlightTile(garment: garments[i], dimmed: generating)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
            if (generating) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
          ],
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final Garment garment;
  final bool dimmed;

  const _HighlightTile({required this.garment, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: garment.displayName,
      child: GestureDetector(
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => GarmentDetailScreen(garmentId: garment.id))),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.45 : 1,
          child: AspectRatio(aspectRatio: 0.8, child: GarmentTile(garment: garment)),
        ),
      ),
    );
  }
}
