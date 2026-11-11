import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/data/garment_repository.dart';
import 'package:closet_ai/features/closet/presentation/screens/closet_screen.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Garment shirt() => Garment(
  id: 1,
  name: 'Camisa',
  category: GarmentCategory.top,
  color: 'azul',
  warmth: WarmthLevel.light,
  imageUrl: 'https://example.invalid/1.jpg',
  createdAt: DateTime(2026),
);

class FakeGarments extends GarmentRepository {
  FakeGarments() : super(Dio());
  final items = [shirt()];
  final List<Map<String, Object>> updates = [];
  final List<int> deleted = [];

  @override
  Future<List<Garment>> list() async => items;

  @override
  Future<Garment> update(
    int id, {
    required String name,
    required String color,
    required GarmentCategory category,
    required WarmthLevel warmth,
  }) async {
    updates.add({'name': name, 'color': color, 'category': category, 'warmth': warmth});
    return Garment(
      id: id,
      name: name,
      category: category,
      color: color,
      warmth: warmth,
      imageUrl: 'https://example.invalid/1.jpg',
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> delete(int id) async => deleted.add(id);
}

void main() {
  late FakeGarments repo;

  Future<void> openDetail(WidgetTester tester) async {
    repo = FakeGarments();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [closetProvider.overrideWith((ref) => ClosetNotifier(repo))],
        child: const MaterialApp(home: Scaffold(body: ClosetScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camisa'));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a garment shows its details', (tester) async {
    await openDetail(tester);

    expect(find.text('Prenda'), findsOneWidget);
    expect(find.text('Parte de arriba'), findsOneWidget);
    expect(find.text('azul'), findsOneWidget);
    expect(find.text('Ligera (calor)'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('editing saves and shows the changes', (tester) async {
    await openDetail(tester);

    await tester.tap(find.byTooltip('Editar prenda'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Camisa'), 'Camisa de lino');
    await tester.tap(find.text('Ligera (calor)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Media (entretiempo)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repo.updates.single, {
      'name': 'Camisa de lino',
      'color': 'azul',
      'category': GarmentCategory.top,
      'warmth': WarmthLevel.medium,
    });
    expect(find.text('Camisa de lino'), findsOneWidget);
    expect(find.text('Media (entretiempo)'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('cancelling the deletion deletes nothing', (tester) async {
    await openDetail(tester);

    await tester.tap(find.byTooltip('Borrar prenda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.deleted, isEmpty);
    expect(find.text('Prenda'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('confirming the deletion removes it and goes back to the closet', (tester) async {
    await openDetail(tester);

    await tester.tap(find.byTooltip('Borrar prenda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se puede deshacer'), findsOneWidget);
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(repo.deleted, [1]);
    expect(find.text('Mi clóset'), findsOneWidget);
    expect(find.text('Camisa'), findsNothing);
  }, semanticsEnabled: false);
}
