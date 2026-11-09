import 'dart:async';
import 'dart:typed_data';

import 'package:closet_ai/core/api_exception.dart';
import 'package:closet_ai/models/garment.dart';
import 'package:closet_ai/repositories/garment_repository.dart';
import 'package:closet_ai/screens/add_garment_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

// PNG transparente de 1x1 para que la vista previa pueda decodificarse.
final _png = Uint8List.fromList(const [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196,
  137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 96, 0, 2, 0, 0, 5, 0, 1, 226, 38, 5, 155, 0, 0, 0, 0, 73, 69, 78,
  68, 174, 66, 96, 130,
]);

class FakePicker extends ImagePicker {
  int picks = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    picks++;
    return XFile.fromData(_png, name: 'foto$picks.png', mimeType: 'image/png');
  }
}

class FakeRepo extends GarmentRepository {
  FakeRepo() : super(Dio());
  final List<Completer<GarmentSuggestion>> pending = [];

  @override
  Future<GarmentSuggestion> suggest(XFile image) {
    final completer = Completer<GarmentSuggestion>();
    pending.add(completer);
    return completer.future;
  }
}

GarmentSuggestion suggestion({String name = 'Suéter de punto', String color = 'verde'}) => GarmentSuggestion(
      name: name,
      color: color,
      category: GarmentCategory.outerwear,
      warmth: WarmthLevel.heavy,
    );

void main() {
  late FakeRepo repo;

  Future<void> pumpScreen(WidgetTester tester) async {
    repo = FakeRepo();
    // Pantalla alta: la lista solo construye los campos que caben en ella.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [garmentRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: AddGarmentScreen(picker: FakePicker())),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Sin pumpAndSettle: mientras se analiza la foto hay un indicador girando.
  Future<void> pickPhoto(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_a_photo_outlined).evaluate().isNotEmpty
        ? find.byIcon(Icons.add_a_photo_outlined)
        : find.byType(Image).first);
    // Un cuadro arranca la animación del panel y el siguiente la termina.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final before = repo.pending.length;
    await tester.tap(find.text('Elegir de la galería'));
    // Leer la foto tarda tiempo real, que el reloj simulado del test no avanza.
    for (var i = 0; i < 40 && repo.pending.length == before; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  String field(WidgetTester tester, int index) =>
      tester.widgetList<TextField>(find.byType(TextField)).elementAt(index).controller!.text;

  Future<void> finish(WidgetTester tester, Completer<GarmentSuggestion> completer, GarmentSuggestion value) async {
    completer.complete(value);
    await tester.pumpAndSettle();
  }

  testWidgets('avisa de Gemini antes de elegir la foto', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Google Gemini'), findsOneWidget);
    expect(find.text('Completando los datos...'), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('llena los cuatro campos desde la foto', (tester) async {
    await pumpScreen(tester);
    await pickPhoto(tester);
    expect(find.text('Completando los datos...'), findsOneWidget);

    await finish(tester, repo.pending.single, suggestion());

    expect(field(tester, 0), 'Suéter de punto');
    expect(field(tester, 1), 'verde');
    expect(find.text(GarmentCategory.outerwear.label), findsOneWidget);
    expect(find.text(WarmthLevel.heavy.label), findsOneWidget);
    expect(find.text('Revisa los datos antes de guardar.'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('no pisa lo que el usuario ya escribió', (tester) async {
    await pumpScreen(tester);
    await pickPhoto(tester);
    await tester.enterText(find.byType(TextField).first, 'Mi favorito');

    await finish(tester, repo.pending.single, suggestion());

    expect(field(tester, 0), 'Mi favorito');
    expect(field(tester, 1), 'verde');
  }, semanticsEnabled: false);

  testWidgets('si falla, explica y deja llenar a mano', (tester) async {
    await pumpScreen(tester);
    await pickPhoto(tester);

    repo.pending.single.completeError(ApiException('Se agotó el límite de autocompletado.'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Se agotó el límite de autocompletado.'), findsOneWidget);
    expect(find.textContaining('a mano'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Buso');
    expect(field(tester, 0), 'Buso');
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  }, semanticsEnabled: false);

  testWidgets('ignora el resultado de una foto ya reemplazada', (tester) async {
    await pumpScreen(tester);
    await pickPhoto(tester);
    await pickPhoto(tester);
    expect(repo.pending, hasLength(2));

    await finish(tester, repo.pending[1], suggestion(name: 'Foto nueva'));
    await finish(tester, repo.pending[0], suggestion(name: 'Foto vieja'));

    expect(field(tester, 0), 'Foto nueva');
  }, semanticsEnabled: false);
}
