import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../core/app_theme.dart';
import '../core/image_url.dart';
import '../core/silhouette.dart';
import '../models/garment.dart';
import '../repositories/look_repository.dart';
import '../state/body_photo_provider.dart';
import '../state/closet_provider.dart';
import '../state/try_on_shapes_provider.dart';
import '../widgets/garment_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_header.dart';
import 'looks_screen.dart';

const _minLayerWidth = 0.12;
const _maxLayerWidth = 1.0;

/// Prenda colocada sobre la foto. La posición y el ancho son fracciones del
/// escenario, para que no cambien con el tamaño de la pantalla.
class TryOnLayer {
  final Garment garment;
  final double centerX;
  final double top;
  final double width;

  /// Zona visible del recorte; null mientras no se haya medido.
  final GarmentShape? shape;

  /// true mientras el usuario no la haya movido ni cambiado de tamaño: así el
  /// ajuste automático no deshace sus cambios.
  final bool autoFit;

  const TryOnLayer({
    required this.garment,
    required this.centerX,
    required this.top,
    required this.width,
    this.shape,
    this.autoFit = true,
  });

  /// Posición inicial aproximada según la parte del cuerpo donde va la prenda.
  factory TryOnLayer.initial(Garment garment) {
    final (top, width) = switch (garment.category) {
      GarmentCategory.top => (0.18, 0.5),
      GarmentCategory.outerwear => (0.17, 0.55),
      GarmentCategory.dress => (0.18, 0.55),
      GarmentCategory.bottom => (0.45, 0.45),
      GarmentCategory.shoes => (0.86, 0.32),
      GarmentCategory.accessory => (0.1, 0.22),
    };
    return TryOnLayer(garment: garment, centerX: 0.5, top: top, width: width);
  }

  TryOnLayer copyWith({double? centerX, double? top, double? width, GarmentShape? shape, bool? autoFit}) =>
      TryOnLayer(
        garment: garment,
        centerX: centerX ?? this.centerX,
        top: top ?? this.top,
        width: width ?? this.width,
        shape: shape ?? this.shape,
        autoFit: autoFit ?? this.autoFit,
      );
}

class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({super.key});

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  final List<TryOnLayer> _layers = [];
  final Set<int> _preparing = {};
  int? _selectedId;
  bool _uploading = false;
  bool _generating = false;
  double _gestureStartWidth = 0;
  BodyShape? _body;
  String? _bodyUrl;
  Size? _stageSize;

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : 'Ocurrió un error inesperado. Intenta de nuevo.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _uploadFrom(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxHeight: 2000);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(bodyPhotoProvider.notifier).upload(picked);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto() async {
    try {
      await ref.read(bodyPhotoProvider.notifier).delete();
      setState(() {
        _layers.clear();
        _selectedId = null;
      });
    } catch (error) {
      _showError(error);
    }
  }

  void _showPhotoOptions({required bool hasPhoto}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _uploadFrom(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _uploadFrom(ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Eliminar mi foto', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deletePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGarment(Garment garment) async {
    if (_preparing.contains(garment.id)) return;
    if (_layers.any((layer) => layer.garment.id == garment.id)) {
      _select(garment.id);
      return;
    }
    setState(() => _preparing.add(garment.id));
    try {
      final ready = await ref.read(closetProvider.notifier).ensureCutout(garment);
      if (!mounted) return;
      setState(() {
        _layers.add(TryOnLayer.initial(ready));
        _selectedId = ready.id;
      });
      _measureGarment(ready);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _preparing.remove(garment.id));
    }
  }

  /// Mide la silueta de la foto una vez y recoloca las prendas que no se han movido a mano.
  void _measureBody(String url) {
    if (_bodyUrl == url) return;
    _bodyUrl = url;
    _body = null;
    ref.read(shapeLoaderProvider).body(fullImageUrl(url)).then((body) {
      if (!mounted || _bodyUrl != url || body == null) return;
      setState(() {
        _body = body;
        for (var i = 0; i < _layers.length; i++) {
          if (_layers[i].autoFit) _layers[i] = _fitted(_layers[i]);
        }
      });
    });
  }

  /// Mide la zona visible de la prenda y, si sigue en ajuste automático, la coloca.
  Future<void> _measureGarment(Garment garment) async {
    final shape = await ref.read(shapeLoaderProvider).garment(fullImageUrl(garment.cutoutUrl!));
    if (!mounted || shape == null) return;
    final index = _layers.indexWhere((layer) => layer.garment.id == garment.id);
    if (index == -1) return;
    setState(() {
      final measured = _layers[index].copyWith(shape: shape);
      _layers[index] = measured.autoFit ? _fitted(measured) : measured;
    });
  }

  /// Posición automática de la capa sobre la silueta; la deja igual si faltan medidas.
  TryOnLayer _fitted(TryOnLayer layer) {
    final body = _body;
    final shape = layer.shape;
    final stage = _stageSize;
    if (body == null || shape == null || stage == null) return layer;
    final fit = fitGarment(layer.garment.category, body, shape);
    if (fit == null) return layer;

    // La foto se muestra completa (BoxFit.contain) y centrada en el escenario.
    final stageAspect = stage.width / stage.height;
    final photoWidth = stageAspect > body.imageAspect ? body.imageAspect / stageAspect : 1.0;
    final photoHeight = stageAspect > body.imageAspect ? 1.0 : stageAspect / body.imageAspect;
    final photoLeft = (1 - photoWidth) / 2;
    final photoTop = (1 - photoHeight) / 2;
    return layer.copyWith(
      centerX: photoLeft + fit.centerX * photoWidth,
      top: photoTop + fit.top * photoHeight,
      width: (fit.width * photoWidth).clamp(_minLayerWidth, _maxLayerWidth),
      autoFit: true,
    );
  }

  /// Prendas que la IA de prueba sabe vestir; el calzado y los accesorios no.
  static bool _canTryOn(Garment garment) =>
      garment.category != GarmentCategory.shoes && garment.category != GarmentCategory.accessory;

  /// Pide a la IA una foto realista con las prendas puestas, en orden de vestir.
  Future<void> _generateLook() async {
    final garmentIds = [
      for (final layer in _layersInWearingOrder())
        if (_canTryOn(layer.garment)) layer.garment.id,
    ];
    setState(() => _generating = true);
    try {
      final look = await ref.read(lookRepositoryProvider).generate(garmentIds);
      ref.invalidate(looksProvider);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LookScreen(look: look)));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _refitSelected() => _updateSelected((layer) => _fitted(layer.copyWith(autoFit: true)));

  /// Capas en orden de vestir (pantalón, blusa, chaqueta encima); dentro de la
  /// misma categoría manda el orden de [_layers], donde la seleccionada va al final.
  List<TryOnLayer> _layersInWearingOrder() {
    final indexed = _layers.indexed.toList()
      ..sort((a, b) {
        final byCategory = layerOrder(a.$2.garment.category).compareTo(layerOrder(b.$2.garment.category));
        return byCategory != 0 ? byCategory : a.$1.compareTo(b.$1);
      });
    return [for (final (_, layer) in indexed) layer];
  }

  /// Selecciona una capa y la trae al frente.
  void _select(int garmentId) {
    setState(() {
      final index = _layers.indexWhere((layer) => layer.garment.id == garmentId);
      _layers.add(_layers.removeAt(index));
      _selectedId = garmentId;
    });
  }

  void _updateSelected(TryOnLayer Function(TryOnLayer layer) update) {
    final index = _layers.indexWhere((layer) => layer.garment.id == _selectedId);
    if (index == -1) return;
    setState(() => _layers[index] = update(_layers[index]));
  }

  void _removeSelected() {
    setState(() {
      _layers.removeWhere((layer) => layer.garment.id == _selectedId);
      _selectedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final photoAsync = ref.watch(bodyPhotoProvider);
    final photoUrl = photoAsync.valueOrNull;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Probador',
            actions: [
              HeaderIconButton(
                icon: Icons.photo_library_outlined,
                tooltip: 'Mis looks',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LooksScreen()),
                ),
              ),
              if (photoUrl != null)
                HeaderIconButton(
                  icon: Icons.person_outline,
                  tooltip: 'Mi foto',
                  onPressed: () => _showPhotoOptions(hasPhoto: true),
                ),
            ],
          ),
          Expanded(
            child: photoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _LoadError(
                message: 'No se pudo cargar tu foto:\n$error',
                onRetry: () => ref.read(bodyPhotoProvider.notifier).load(),
              ),
              data: (url) {
                if (url == null) return _emptyState();
                _measureBody(url);
                return _dressingRoom(url);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
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
                const Text('• De frente, de la cabeza a los pies\n• Con ropa ajustada y buena luz\n• Con un fondo sencillo'),
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
        PrimaryButton(
          label: 'Subir mi foto',
          loading: _uploading,
          onPressed: () => _showPhotoOptions(hasPhoto: false),
        ),
      ],
    );
  }

  Widget _dressingRoom(String url) {
    final garments = ref.watch(closetProvider);
    final selected = _layers.where((layer) => layer.garment.id == _selectedId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, floatingNavClearance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _stage(url)),
          SizedBox(
            height: 52,
            child: selected == null
                ? Center(
                    child: Text(
                      _layers.isEmpty ? 'Toca una prenda para ponértela' : 'Toca una prenda de la foto para ajustarla',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : Row(
                    children: [
                      const Icon(Icons.photo_size_select_small, size: 18),
                      Expanded(
                        child: Slider(
                          min: _minLayerWidth,
                          max: _maxLayerWidth,
                          value: selected.width,
                          semanticFormatterCallback: (value) => 'Tamaño ${(value * 100).round()}%',
                          onChanged: (value) =>
                              _updateSelected((layer) => layer.copyWith(width: value, autoFit: false)),
                        ),
                      ),
                      if (_body != null && selected.shape != null)
                        IconButton(
                          tooltip: 'Ajustar automáticamente',
                          icon: const Icon(Icons.auto_fix_high),
                          onPressed: _refitSelected,
                        ),
                      IconButton(
                        tooltip: 'Quitar prenda',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _removeSelected,
                      ),
                    ],
                  ),
          ),
          SizedBox(
            height: 76,
            child: garments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('No se pudo cargar tu clóset: $error')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Agrega prendas en la pestaña Clóset.'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => _garmentButton(items[index]),
                    ),
            ),
          ),
          if (_layers.any((layer) => _canTryOn(layer.garment))) ...[
            const SizedBox(height: 10),
            PrimaryButton(
              label: _generating ? 'Creando tu look...' : 'Ver cómo me queda',
              loading: _generating,
              onPressed: _generateLook,
            ),
            const SizedBox(height: 4),
            Text(
              [
                'El servicio FASHN recibe tu foto y estas prendas y dibuja el look; tarda unos segundos por prenda.',
                if (_layers.any((layer) => !_canTryOn(layer.garment)))
                  'El calzado y los accesorios no se incluyen.',
              ].join(' '),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stage(String url) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            _stageSize = size;
            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selectedId = null),
                  child: Image.network(
                    fullImageUrl(url),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => _LoadError(
                      message: 'No se pudo mostrar tu foto.',
                      onRetry: () => ref.read(bodyPhotoProvider.notifier).load(),
                    ),
                  ),
                ),
                for (final layer in _layersInWearingOrder()) _layerWidget(layer, size),
                if (_uploading) const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _layerWidget(TryOnLayer layer, Size stage) {
    final width = layer.width * stage.width;
    final selected = layer.garment.id == _selectedId;
    return Positioned(
      left: layer.centerX * stage.width - width / 2,
      top: layer.top * stage.height,
      width: width,
      child: Semantics(
        label: layer.garment.name.isNotEmpty ? layer.garment.name : layer.garment.category.label,
        button: true,
        selected: selected,
        child: GestureDetector(
          key: ValueKey('layer-${layer.garment.id}'),
          onTap: () => _select(layer.garment.id),
          onScaleStart: (_) {
            if (!selected) _select(layer.garment.id);
            _gestureStartWidth = layer.width;
          },
          onScaleUpdate: (details) => _updateSelected((current) => current.copyWith(
                centerX: (current.centerX + details.focalPointDelta.dx / stage.width).clamp(0.0, 1.0),
                top: (current.top + details.focalPointDelta.dy / stage.height).clamp(0.0, 1.0),
                width: details.pointerCount > 1
                    ? (_gestureStartWidth * details.scale).clamp(_minLayerWidth, _maxLayerWidth)
                    : current.width,
                autoFit: false,
              )),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _garmentImage(layer, width),
          ),
        ),
      ),
    );
  }

  /// Imagen de la prenda; ya medida, se muestra solo su zona visible, sin bordes vacíos.
  Widget _garmentImage(TryOnLayer layer, double width) {
    final url = fullImageUrl(layer.garment.cutoutUrl!);
    Widget errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) => SizedBox(
          height: width,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        );
    final shape = layer.shape;
    if (shape == null) {
      return Image.network(url, fit: BoxFit.fitWidth, errorBuilder: errorBuilder);
    }
    final height = width * shape.aspect;
    final fullWidth = width / (shape.right - shape.left);
    final fullHeight = height / (shape.bottom - shape.top);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: fullWidth,
          maxWidth: fullWidth,
          minHeight: fullHeight,
          maxHeight: fullHeight,
          child: Transform.translate(
            offset: Offset(-shape.left * fullWidth, -shape.top * fullHeight),
            child: Image.network(url, fit: BoxFit.fill, errorBuilder: errorBuilder),
          ),
        ),
      ),
    );
  }

  Widget _garmentButton(Garment garment) {
    final scheme = Theme.of(context).colorScheme;
    final worn = _layers.any((layer) => layer.garment.id == garment.id);
    return Semantics(
      button: true,
      selected: worn,
      label: garment.name.isNotEmpty ? garment.name : garment.category.label,
      child: GestureDetector(
        key: ValueKey('garment-${garment.id}'),
        onTap: () => _addGarment(garment),
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
              if (_preparing.contains(garment.id))
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

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
