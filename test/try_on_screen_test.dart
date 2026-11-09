import 'dart:async';
import 'dart:typed_data';

import 'package:closet_ai/core/api_exception.dart';
import 'package:closet_ai/core/silhouette.dart';
import 'package:closet_ai/models/garment.dart';
import 'package:closet_ai/repositories/body_photo_repository.dart';
import 'package:closet_ai/repositories/garment_repository.dart';
import 'package:closet_ai/screens/try_on_screen.dart';
import 'package:closet_ai/state/body_photo_provider.dart';
import 'package:closet_ai/state/closet_provider.dart';
import 'package:closet_ai/state/theme_provider.dart';
import 'package:closet_ai/state/try_on_shapes_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Garment garment(int id, {String? cutout}) => Garment(
      id: id,
      name: 'Prenda $id',
      category: GarmentCategory.top,
      color: 'gris',
      warmth: WarmthLevel.medium,
      imageUrl: 'https://example.invalid/$id.jpg',
      cutoutUrl: cutout,
      createdAt: DateTime(2026),
    );

class FakeGarments extends GarmentRepository {
  FakeGarments(this.items) : super(Dio());
  final List<Garment> items;
  int cutoutCalls = 0;
  bool failCutout = false;

  @override
  Future<List<Garment>> list() async => items;

  @override
  Future<Garment> createCutout(int id) async {
    cutoutCalls++;
    if (failCutout) throw ApiException('Se agotó el límite de recortes.');
    return garment(id, cutout: 'https://example.invalid/$id.png');
  }
}

class FakeBodyPhoto extends BodyPhotoRepository {
  FakeBodyPhoto(this.url) : super(Dio());
  String? url;

  @override
  Future<String?> current() async => url;

  @override
  Future<String> upload(XFile image) async => url = 'https://example.invalid/yo.png';

  @override
  Future<void> delete() async => url = null;
}

/// Silueta de 100x200 con la cabeza centrada; los hombros miden 40 px.
BodyShape testBody() {
  final data = Uint8List(100 * 200 * 4);
  void box(int x0, int y0, int x1, int y1) {
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        data[(y * 100 + x) * 4 + 3] = 255;
      }
    }
  }

  box(40, 10, 60, 30);
  box(30, 40, 70, 110);
  box(32, 110, 48, 190);
  box(52, 110, 68, 190);
  return analyzeBody(RgbaPixels(data, 100, 200))!;
}

class FakeShapes implements ShapeLoader {
  FakeShapes({this.bodyShape, this.garmentShape});
  final BodyShape? bodyShape;
  final GarmentShape? garmentShape;
  final Completer<void> bodyGate = Completer<void>()..complete();

  @override
  Future<BodyShape?> body(String url) async {
    await bodyGate.future;
    return bodyShape;
  }

  @override
  Future<GarmentShape?> garment(String url) async => garmentShape;
}

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    FakeGarments garments,
    FakeBodyPhoto photo, {
    ShapeLoader? shapes,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          garmentRepositoryProvider.overrideWithValue(garments),
          bodyPhotoRepositoryProvider.overrideWithValue(photo),
          closetProvider.overrideWith((ref) => ClosetNotifier(garments)),
          bodyPhotoProvider.overrideWith((ref) => BodyPhotoNotifier(photo)),
          shapeLoaderProvider.overrideWithValue(shapes ?? FakeShapes()),
        ],
        child: const MaterialApp(home: Scaffold(body: TryOnScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  const layerKey = ValueKey('layer-1');
  const garmentKey = ValueKey('garment-1');

  testWidgets('sin foto avisa que se envía a remove.bg', (tester) async {
    await pumpScreen(tester, FakeGarments([garment(1)]), FakeBodyPhoto(null));

    expect(find.textContaining('remove.bg'), findsOneWidget);
    expect(find.text('Subir mi foto'), findsOneWidget);
    expect(find.byKey(garmentKey), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('tocar una prenda la pone sobre la foto y no la duplica', (tester) async {
    final garments = FakeGarments([garment(1)]);
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));

    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();

    expect(find.byKey(layerKey), findsOneWidget);
    expect(garments.cutoutCalls, 1);
  }, semanticsEnabled: false);

  testWidgets('una prenda que ya tiene recorte no gasta otro', (tester) async {
    final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png')]);
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));

    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();

    expect(find.byKey(layerKey), findsOneWidget);
    expect(garments.cutoutCalls, 0);
  }, semanticsEnabled: false);

  testWidgets('si falla el recorte muestra el motivo y no agrega la prenda', (tester) async {
    final garments = FakeGarments([garment(1)])..failCutout = true;
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));

    await tester.tap(find.byKey(garmentKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Se agotó el límite de recortes.'), findsOneWidget);
    expect(find.byKey(layerKey), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('arrastrar mueve la prenda, el control la agranda y se puede quitar', (tester) async {
    final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png')]);
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));
    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();

    Positioned positioned() => tester.widget<Positioned>(
          find.ancestor(of: find.byKey(layerKey), matching: find.byType(Positioned)).first,
        );
    final before = positioned();

    await tester.drag(find.byKey(layerKey), const Offset(30, 40));
    await tester.pumpAndSettle();
    expect(positioned().left, greaterThan(before.left!));
    expect(positioned().top, greaterThan(before.top!));

    final widthBefore = positioned().width!;
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(slider.value + 0.2);
    await tester.pumpAndSettle();
    expect(positioned().width, greaterThan(widthBefore));

    await tester.tap(find.byTooltip('Quitar prenda'));
    await tester.pumpAndSettle();
    expect(find.byKey(layerKey), findsNothing);
  }, semanticsEnabled: false);

  group('ajuste automático', () {
    const shirt = GarmentShape(left: 0.1, top: 0.2, right: 0.9, bottom: 0.8, aspect: 0.6);

    Positioned layerPosition(WidgetTester tester) => tester.widget<Positioned>(
          find.ancestor(of: find.byKey(layerKey), matching: find.byType(Positioned)).first,
        );

    Future<void> addShirt(WidgetTester tester) async {
      final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png')]);
      await pumpScreen(
        tester,
        garments,
        FakeBodyPhoto('https://example.invalid/yo.png'),
        shapes: FakeShapes(bodyShape: testBody(), garmentShape: shirt),
      );
      await tester.tap(find.byKey(garmentKey));
      await tester.pumpAndSettle();
    }

    testWidgets('coloca la prenda sobre los hombros, centrada en el cuerpo', (tester) async {
      await addShirt(tester);

      final position = layerPosition(tester);
      final stage = tester.getSize(find.byType(LayoutBuilder).first);
      final layerCenter = position.left! + position.width! / 2;
      // El cuerpo de la silueta está centrado en la foto, y la foto en el escenario.
      expect(layerCenter, closeTo(stage.width / 2, 1));
      // Sin bordes vacíos: el alto sale de la zona visible de la prenda.
      expect(tester.getSize(find.byKey(layerKey)).height, closeTo(position.width! * shirt.aspect + 3, 2));
      expect(find.byTooltip('Ajustar automáticamente'), findsOneWidget);
    }, semanticsEnabled: false);

    testWidgets('lo que se mueve a mano no se reacomoda, salvo con el botón', (tester) async {
      await addShirt(tester);
      final fitted = layerPosition(tester);

      await tester.drag(find.byKey(layerKey), const Offset(40, 60));
      await tester.pumpAndSettle();
      expect(layerPosition(tester).top, greaterThan(fitted.top!));

      await tester.tap(find.byTooltip('Ajustar automáticamente'));
      await tester.pumpAndSettle();
      expect(layerPosition(tester).top, closeTo(fitted.top!, 0.01));
      expect(layerPosition(tester).left, closeTo(fitted.left!, 0.01));
    }, semanticsEnabled: false);

    testWidgets('la chaqueta queda sobre la blusa aunque se agregue antes', (tester) async {
      final jacket = Garment(
        id: 2,
        name: 'Chaqueta',
        category: GarmentCategory.outerwear,
        color: 'gris',
        warmth: WarmthLevel.heavy,
        imageUrl: 'https://example.invalid/2.jpg',
        cutoutUrl: 'https://example.invalid/2.png',
        createdAt: DateTime(2026),
      );
      final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png'), jacket]);
      await pumpScreen(
        tester,
        garments,
        FakeBodyPhoto('https://example.invalid/yo.png'),
        shapes: FakeShapes(bodyShape: testBody(), garmentShape: shirt),
      );

      await tester.tap(find.byKey(const ValueKey('garment-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(garmentKey));
      await tester.pumpAndSettle();

      // En un Stack, lo que se dibuja después queda encima.
      final order = tester
          .widgetList<GestureDetector>(find.byWidgetPredicate((w) => w.key.toString().contains('layer-')))
          .map((w) => (w.key! as ValueKey<String>).value)
          .toList();
      expect(order, ['layer-1', 'layer-2']);
    }, semanticsEnabled: false);

    testWidgets('si no se puede medir la foto, la prenda queda a mano como antes', (tester) async {
      final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png')]);
      await pumpScreen(
        tester,
        garments,
        FakeBodyPhoto('https://example.invalid/yo.png'),
        shapes: FakeShapes(garmentShape: shirt),
      );
      await tester.tap(find.byKey(garmentKey));
      await tester.pumpAndSettle();

      expect(find.byKey(layerKey), findsOneWidget);
      expect(find.byTooltip('Ajustar automáticamente'), findsNothing);
    }, semanticsEnabled: false);
  });
}
