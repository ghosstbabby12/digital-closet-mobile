import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';

enum HighlightKind { forgotten, lastOutfit, closet }

/// Garments worth showing under the stylist button.
class ClosetHighlights {
  final HighlightKind kind;
  final List<Garment> garments;

  const ClosetHighlights(this.kind, this.garments);
}

/// Garments not worn in the last [recentDays] (the most forgotten first). If
/// everything was worn, the last outfit; with no outfits, the first garments.
ClosetHighlights pickHighlights(
  List<Garment> closet,
  List<Outfit> history, {
  required DateTime now,
  int recentDays = 14,
  int max = 4,
}) {
  final since = now.subtract(Duration(days: recentDays));
  final worn = {
    for (final outfit in history)
      if (outfit.createdAt.isAfter(since)) ...outfit.garments.map((g) => g.id),
  };
  final forgotten = closet.where((g) => !worn.contains(g.id)).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  if (forgotten.isNotEmpty) return ClosetHighlights(HighlightKind.forgotten, forgotten.take(max).toList());
  final last = history.isNotEmpty ? history.first : null;
  if (last != null && last.garments.isNotEmpty) {
    return ClosetHighlights(HighlightKind.lastOutfit, last.garments.take(max).toList());
  }
  return ClosetHighlights(HighlightKind.closet, closet.take(max).toList());
}
