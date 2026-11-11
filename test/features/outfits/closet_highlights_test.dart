import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/outfits/domain/closet_highlights.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 11, 10);

Garment garment(int id, {DateTime? added}) => Garment(
  id: id,
  name: 'Prenda $id',
  category: GarmentCategory.top,
  color: 'gris',
  warmth: WarmthLevel.medium,
  imageUrl: 'https://example.invalid/$id.jpg',
  createdAt: added ?? DateTime(2026, 1, id),
);

Outfit outfit(List<Garment> garments, DateTime created) => Outfit(
  id: created.day,
  occasion: 'casual',
  weatherTempC: 18,
  weatherCondition: 'nubes',
  explanation: '',
  garments: garments,
  createdAt: created,
);

void main() {
  test('shows the garments not worn lately, the oldest first', () {
    final closet = [garment(3), garment(1), garment(2)];
    final history = [
      outfit([garment(2)], now.subtract(const Duration(days: 3))),
    ];

    final highlights = pickHighlights(closet, history, now: now);

    expect(highlights.kind, HighlightKind.forgotten);
    expect(highlights.garments.map((g) => g.id), [1, 3]);
  });

  test('garments worn long ago count as forgotten', () {
    final history = [
      outfit([garment(1)], now.subtract(const Duration(days: 30))),
    ];

    expect(pickHighlights([garment(1)], history, now: now).kind, HighlightKind.forgotten);
  });

  test('when everything was worn, shows the last outfit', () {
    final closet = [garment(1), garment(2)];
    final history = [outfit(closet, now.subtract(const Duration(days: 1)))];

    final highlights = pickHighlights(closet, history, now: now);

    expect(highlights.kind, HighlightKind.lastOutfit);
    expect(highlights.garments, hasLength(2));
  });

  test('shows at most four garments', () {
    final closet = [for (var id = 1; id <= 6; id++) garment(id)];

    expect(pickHighlights(closet, [], now: now).garments, hasLength(4));
  });
}
