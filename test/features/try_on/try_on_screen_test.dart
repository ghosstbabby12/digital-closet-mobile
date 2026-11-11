import 'dart:async';
import 'dart:typed_data';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/features/try_on/domain/silhouette.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/try_on/domain/look.dart';
import 'package:closet_ai/features/try_on/data/body_photo_repository.dart';
import 'package:closet_ai/features/closet/data/garment_repository.dart';
import 'package:closet_ai/features/try_on/data/look_repository.dart';
import 'package:closet_ai/features/try_on/presentation/screens/looks_screen.dart';
import 'package:closet_ai/features/try_on/presentation/screens/try_on_screen.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/body_photo_controller.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:closet_ai/features/try_on/data/shape_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:closet_ai/core/storage/preferences_provider.dart';

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

/// A 100x200 silhouette with a centered head; the shoulders are 40 px wide.
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

class FakeLooks extends LookRepository {
  FakeLooks() : super(Dio());
  final List<List<int>> requests = [];
  bool fail = false;

  @override
  Future<Look> generate(List<int> garmentIds) async {
    requests.add(garmentIds);
    if (fail) throw ApiException('Se acabaron los créditos de FASHN. Recarga para seguir.');
    return Look(id: 1, imageUrl: 'https://example.invalid/look.png', garmentIds: garmentIds, createdAt: DateTime(2026));
  }

  @override
  Future<List<Look>> list() async => [];
}

late FakeLooks looks;

void main() {
  // The app does this in main(); the look screen shows the date in Spanish.
  setUpAll(() => initializeDateFormatting('es'));

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
          lookRepositoryProvider.overrideWithValue(looks = FakeLooks()),
        ],
        child: const MaterialApp(home: Scaffold(body: TryOnScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  const layerKey = ValueKey('layer-1');
  const garmentKey = ValueKey('garment-1');

  testWidgets('without a photo it warns that it is sent to remove.bg', (tester) async {
    await pumpScreen(tester, FakeGarments([garment(1)]), FakeBodyPhoto(null));

    expect(find.textContaining('remove.bg'), findsOneWidget);
    expect(find.text('Subir mi foto'), findsOneWidget);
    expect(find.byKey(garmentKey), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('tapping a garment puts it on the photo once', (tester) async {
    final garments = FakeGarments([garment(1)]);
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));

    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();

    expect(find.byKey(layerKey), findsOneWidget);
    expect(garments.cutoutCalls, 1);
  }, semanticsEnabled: false);

  testWidgets('a garment that already has a cutout spends no other', (tester) async {
    final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png')]);
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));

    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();

    expect(find.byKey(layerKey), findsOneWidget);
    expect(garments.cutoutCalls, 0);
  }, semanticsEnabled: false);

  testWidgets('a failed cutout shows the reason and adds nothing', (tester) async {
    final garments = FakeGarments([garment(1)])..failCutout = true;
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));

    await tester.tap(find.byKey(garmentKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Se agotó el límite de recortes.'), findsOneWidget);
    expect(find.byKey(layerKey), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('dragging moves the garment, the slider resizes it and it can be removed', (tester) async {
    final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png')]);
    await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));
    await tester.tap(find.byKey(garmentKey));
    await tester.pumpAndSettle();

    Positioned positioned() =>
        tester.widget<Positioned>(find.ancestor(of: find.byKey(layerKey), matching: find.byType(Positioned)).first);
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

  group('automatic fitting', () {
    const shirt = GarmentShape(left: 0.1, top: 0.2, right: 0.9, bottom: 0.8, aspect: 0.6);

    Positioned layerPosition(WidgetTester tester) =>
        tester.widget<Positioned>(find.ancestor(of: find.byKey(layerKey), matching: find.byType(Positioned)).first);

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

    testWidgets('places the garment on the shoulders, centered on the body', (tester) async {
      await addShirt(tester);

      final position = layerPosition(tester);
      final stage = tester.getSize(find.byType(LayoutBuilder).first);
      final layerCenter = position.left! + position.width! / 2;
      // The silhouette's body is centered in the photo, and the photo on the stage.
      expect(layerCenter, closeTo(stage.width / 2, 1));
      // No empty borders: the height comes from the garment's visible area.
      expect(tester.getSize(find.byKey(layerKey)).height, closeTo(position.width! * shirt.aspect + 3, 2));
      expect(find.byTooltip('Ajustar automáticamente'), findsOneWidget);
    }, semanticsEnabled: false);

    testWidgets('what is moved by hand is not refitted, except with the button', (tester) async {
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

    testWidgets('the jacket stays over the blouse even if added first', (tester) async {
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

      // In a Stack, what is painted later ends up on top.
      final order = tester
          .widgetList<GestureDetector>(find.byWidgetPredicate((w) => w.key.toString().contains('layer-')))
          .map((w) => (w.key! as ValueKey<String>).value)
          .toList();
      expect(order, ['layer-1', 'layer-2']);
    }, semanticsEnabled: false);

    testWidgets('when the photo cannot be measured, the garment stays manual', (tester) async {
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

  group('see how it looks', () {
    Garment jacket() => Garment(
      id: 2,
      name: 'Chaqueta',
      category: GarmentCategory.outerwear,
      color: 'gris',
      warmth: WarmthLevel.heavy,
      imageUrl: 'https://example.invalid/2.jpg',
      cutoutUrl: 'https://example.invalid/2.png',
      createdAt: DateTime(2026),
    );

    Future<void> wearBoth(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final garments = FakeGarments([garment(1, cutout: 'https://example.invalid/1.png'), jacket()]);
      await pumpScreen(tester, garments, FakeBodyPhoto('https://example.invalid/yo.png'));
      expect(find.text('Ver cómo me queda'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('garment-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(garmentKey));
      await tester.pumpAndSettle();
    }

    testWidgets('sends the garments in wearing order and opens the result', (tester) async {
      await wearBoth(tester);

      expect(find.textContaining('FASHN'), findsOneWidget);
      await tester.tap(find.text('Ver cómo me queda'));
      await tester.pumpAndSettle();

      // The blouse (1) goes before the jacket (2), even though the jacket was put on first.
      expect(looks.requests, [
        [1, 2],
      ]);
      expect(find.byType(LookScreen), findsOneWidget);
    }, semanticsEnabled: false);

    testWidgets('shoes are also sent to the AI', (tester) async {
      final shoes = Garment(
        id: 3,
        name: 'Tenis',
        category: GarmentCategory.shoes,
        color: 'blanco',
        warmth: WarmthLevel.light,
        imageUrl: 'https://example.invalid/3.jpg',
        cutoutUrl: 'https://example.invalid/3.png',
        createdAt: DateTime(2026),
      );
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        FakeGarments([garment(1, cutout: 'https://example.invalid/1.png'), shoes]),
        FakeBodyPhoto('https://example.invalid/yo.png'),
      );

      await tester.tap(find.byKey(const ValueKey('garment-3')));
      await tester.pumpAndSettle();
      expect(find.text('Ver cómo me queda'), findsOneWidget);

      await tester.tap(find.byKey(garmentKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('no se incluyen'), findsNothing);
      await tester.tap(find.text('Ver cómo me queda'));
      await tester.pumpAndSettle();

      // In wearing order; the server puts the shoes last anyway.
      expect(looks.requests, [
        [3, 1],
      ]);
    }, semanticsEnabled: false);

    testWidgets('on failure it shows the reason and allows a retry', (tester) async {
      await wearBoth(tester);
      looks.fail = true;

      await tester.tap(find.text('Ver cómo me queda'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Se acabaron los créditos de FASHN. Recarga para seguir.'), findsOneWidget);
      expect(find.byType(LookScreen), findsNothing);
      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Ver cómo me queda'));
      expect(button.onPressed, isNotNull);
    }, semanticsEnabled: false);
  });
}
