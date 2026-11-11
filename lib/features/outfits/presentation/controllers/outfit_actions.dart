import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/outfits/data/outfit_repository.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:closet_ai/features/outfits/presentation/controllers/outfit_controller.dart';
import 'package:closet_ai/features/weather/domain/weather.dart';

/// One-off outfit actions that also refresh the history.
class OutfitActions {
  OutfitActions(this._ref);

  final Ref _ref;

  OutfitRepository get _repository => _ref.read(outfitRepositoryProvider);

  /// Asks the stylist for an outfit for a calendar event.
  Future<Outfit> planEvent({
    required String title,
    required DateTime day,
    required String occasion,
    required City city,
  }) async {
    final outfit = await _repository.generate(
      occasion: occasion,
      lat: city.lat,
      lon: city.lon,
      eventTitle: title,
      eventDate: day,
    );
    _ref.invalidate(outfitHistoryProvider);
    return outfit;
  }

  Future<void> delete(int outfitId) async {
    await _repository.delete(outfitId);
    _ref.invalidate(outfitHistoryProvider);
  }
}

final outfitActionsProvider = Provider<OutfitActions>(OutfitActions.new);
