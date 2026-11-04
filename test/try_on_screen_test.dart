import 'package:closet_ai/core/api_exception.dart';
import 'package:closet_ai/models/garment.dart';
import 'package:closet_ai/repositories/body_photo_repository.dart';
import 'package:closet_ai/repositories/garment_repository.dart';
import 'package:closet_ai/screens/try_on_screen.dart';
import 'package:closet_ai/state/body_photo_provider.dart';
import 'package:closet_ai/state/closet_provider.dart';
import 'package:closet_ai/state/theme_provider.dart';
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

void main() {
  Future<void> pumpScreen(WidgetTester tester, FakeGarments garments, FakeBodyPhoto photo) async {
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
}
