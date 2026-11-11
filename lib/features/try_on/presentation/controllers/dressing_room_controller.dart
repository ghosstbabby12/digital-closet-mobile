import 'dart:ui' show Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/network/image_url.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:closet_ai/features/try_on/data/look_repository.dart';
import 'package:closet_ai/features/try_on/data/shape_loader.dart';
import 'package:closet_ai/features/try_on/domain/layer_fitting.dart';
import 'package:closet_ai/features/try_on/domain/look.dart';
import 'package:closet_ai/features/try_on/domain/silhouette.dart';
import 'package:closet_ai/features/try_on/domain/try_on_layer.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/looks_controller.dart';

class DressingRoomState {
  final List<TryOnLayer> layers;
  final int? selectedId;

  /// Garments whose cutout is being prepared.
  final Set<int> preparing;
  final BodyShape? body;
  final bool generating;

  const DressingRoomState({
    this.layers = const [],
    this.selectedId,
    this.preparing = const {},
    this.body,
    this.generating = false,
  });

  TryOnLayer? get selected => layers.where((layer) => layer.garmentId == selectedId).firstOrNull;
  List<TryOnLayer> get wearingOrder => inWearingOrder(layers);
  List<TryOnLayer> get aiLayers => layers.where((layer) => canTryOnWithAi(layer.garment)).toList();
  bool get hasLayersAiSkips => layers.any((layer) => !canTryOnWithAi(layer.garment));
  bool isWorn(int garmentId) => layers.any((layer) => layer.garmentId == garmentId);

  DressingRoomState copyWith({
    List<TryOnLayer>? layers,
    int? Function()? selectedId,
    Set<int>? preparing,
    BodyShape? body,
    bool? generating,
  }) => DressingRoomState(
    layers: layers ?? this.layers,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
    preparing: preparing ?? this.preparing,
    body: body ?? this.body,
    generating: generating ?? this.generating,
  );
}

/// Layers on the body photo, the selection, and the actions of the try-on screen.
class DressingRoomController extends StateNotifier<DressingRoomState> {
  DressingRoomController(this._ref) : super(const DressingRoomState());

  final Ref _ref;
  Size? _stage;
  String? _bodyUrl;

  void setStageSize(Size size) => _stage = size;

  /// Puts a garment on (removing its background first if needed). Throws if the cutout fails.
  Future<void> addGarment(Garment garment) async {
    if (state.preparing.contains(garment.id)) return;
    if (state.isWorn(garment.id)) return select(garment.id);
    state = state.copyWith(preparing: {...state.preparing, garment.id});
    try {
      final ready = await _ref.read(closetProvider.notifier).ensureCutout(garment);
      if (!mounted) return;
      state = state.copyWith(layers: [...state.layers, TryOnLayer.initial(ready)], selectedId: () => ready.id);
      _measureGarment(ready);
    } finally {
      if (mounted) state = state.copyWith(preparing: {...state.preparing}..remove(garment.id));
    }
  }

  /// Wears a whole outfit, replacing what was on. Returns the first error, if any.
  Future<Object?> wearOutfit(List<Garment> garments) async {
    clear();
    Object? firstError;
    for (final garment in garments) {
      if (!mounted) break;
      try {
        await addGarment(garment);
      } catch (error) {
        firstError ??= error;
      }
    }
    return firstError;
  }

  /// Measures the body once and refits every layer the user has not moved.
  void measureBody(String url) {
    if (_bodyUrl == url) return;
    _bodyUrl = url;
    // A new photo: forget the old measurements until the new ones arrive.
    state = DressingRoomState(
      layers: state.layers,
      selectedId: state.selectedId,
      preparing: state.preparing,
      generating: state.generating,
    );
    _ref.read(shapeLoaderProvider).body(fullImageUrl(url)).then((body) {
      if (!mounted || _bodyUrl != url || body == null) return;
      state = state.copyWith(
        body: body,
        layers: [for (final layer in state.layers) layer.autoFit ? fitLayer(layer, body, _stage) : layer],
      );
    });
  }

  Future<void> _measureGarment(Garment garment) async {
    final shape = await _ref.read(shapeLoaderProvider).garment(fullImageUrl(garment.cutoutUrl!));
    if (!mounted || shape == null) return;
    _updateLayer(garment.id, (layer) {
      final measured = layer.copyWith(shape: shape);
      return measured.autoFit ? fitLayer(measured, state.body, _stage) : measured;
    });
  }

  /// Selects a layer and brings it to the front.
  void select(int garmentId) {
    final layer = state.layers.firstWhere((layer) => layer.garmentId == garmentId);
    state = state.copyWith(
      layers: [...state.layers.where((other) => other.garmentId != garmentId), layer],
      selectedId: () => garmentId,
    );
  }

  void deselect() => state = state.copyWith(selectedId: () => null);

  void moveSelected(double dx, double dy, {double? width}) => _updateSelected(
    (layer) => layer.copyWith(
      centerX: (layer.centerX + dx).clamp(0.0, 1.0),
      top: (layer.top + dy).clamp(0.0, 1.0),
      width: width?.clamp(minLayerWidth, maxLayerWidth),
      autoFit: false,
    ),
  );

  void resizeSelected(double width) => _updateSelected((layer) => layer.copyWith(width: width, autoFit: false));

  void refitSelected() => _updateSelected((layer) => fitLayer(layer.copyWith(autoFit: true), state.body, _stage));

  void removeSelected() => state = state.copyWith(
    layers: state.layers.where((layer) => layer.garmentId != state.selectedId).toList(),
    selectedId: () => null,
  );

  void clear() => state = state.copyWith(layers: [], selectedId: () => null);

  /// Asks the AI for a realistic photo with the garments on, in wearing order.
  Future<Look> generateLook() async {
    final garmentIds = [
      for (final layer in state.wearingOrder)
        if (canTryOnWithAi(layer.garment)) layer.garmentId,
    ];
    state = state.copyWith(generating: true);
    try {
      final look = await _ref.read(lookRepositoryProvider).generate(garmentIds);
      _ref.invalidate(looksProvider);
      return look;
    } finally {
      if (mounted) state = state.copyWith(generating: false);
    }
  }

  void _updateSelected(TryOnLayer Function(TryOnLayer layer) update) {
    final id = state.selectedId;
    if (id != null) _updateLayer(id, update);
  }

  void _updateLayer(int garmentId, TryOnLayer Function(TryOnLayer layer) update) {
    state = state.copyWith(
      layers: [for (final layer in state.layers) layer.garmentId == garmentId ? update(layer) : layer],
    );
  }
}

final dressingRoomProvider = StateNotifierProvider.autoDispose<DressingRoomController, DressingRoomState>(
  DressingRoomController.new,
);
