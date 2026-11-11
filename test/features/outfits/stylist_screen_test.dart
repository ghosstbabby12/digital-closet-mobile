import 'dart:convert';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/core/storage/preferences_provider.dart';
import 'package:closet_ai/features/closet/data/garment_repository.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/outfits/data/outfit_repository.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:closet_ai/features/outfits/presentation/screens/stylist_screen.dart';
import 'package:closet_ai/features/weather/data/weather_json.dart';
import 'package:closet_ai/features/weather/data/weather_repository.dart';
import 'package:closet_ai/features/weather/domain/weather.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final medellin = City(name: 'Medellín', state: 'Antioquia', country: 'CO', lat: 6.24, lon: -75.57);
final cali = City(name: 'Cali', state: 'Valle del Cauca', country: 'CO', lat: 3.45, lon: -76.53);

Garment blouse(int id) => Garment(
  id: id,
  name: 'Blusa $id',
  category: GarmentCategory.top,
  color: 'blanco',
  warmth: WarmthLevel.light,
  imageUrl: 'https://example.invalid/$id.jpg',
  createdAt: DateTime(2026, 1, id),
);

class FakeWeather extends WeatherRepository {
  FakeWeather() : super(Dio());
  final List<(double, double)> requests = [];
  final List<String> searches = [];

  @override
  Future<Weather> current({required double lat, required double lon}) async {
    requests.add((lat, lon));
    return Weather(tempC: 24, feelsLikeC: 25, condition: 'nubes', conditionMain: 'Clouds', city: 'Barrio');
  }

  @override
  Future<List<City>> searchCities(String query) async {
    searches.add(query);
    return [cali];
  }
}

class FakeGarments extends GarmentRepository {
  FakeGarments(this.items) : super(Dio());
  final List<Garment> items;

  @override
  Future<List<Garment>> list() async => items;
}

class FakeOutfits extends OutfitRepository {
  FakeOutfits() : super(Dio());
  (double, double)? requested;

  @override
  Future<List<Outfit>> history() async => [];

  @override
  Future<Outfit> generate({
    required String occasion,
    required double lat,
    required double lon,
    String? eventTitle,
    DateTime? eventDate,
  }) async {
    requested = (lat, lon);
    throw ApiException('stopped by the test');
  }
}

void main() {
  late FakeWeather weather;
  late FakeOutfits outfits;
  late SharedPreferences preferences;

  Future<void> pumpScreen(WidgetTester tester, {City? saved, List<Garment>? closet}) async {
    SharedPreferences.setMockInitialValues({if (saved != null) 'weather_city': jsonEncode(saved.toJson())});
    preferences = await SharedPreferences.getInstance();
    weather = FakeWeather();
    outfits = FakeOutfits();
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          weatherRepositoryProvider.overrideWithValue(weather),
          outfitRepositoryProvider.overrideWithValue(outfits),
          garmentRepositoryProvider.overrideWithValue(FakeGarments(closet ?? [blouse(1), blouse(2)])),
        ],
        child: const MaterialApp(home: Scaffold(body: StylistScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  ElevatedButton mainButton(WidgetTester tester) => tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  testWidgets('shows city, weather and a tip in one card', (tester) async {
    await pumpScreen(tester, saved: medellin);

    expect(weather.requests, [(6.24, -75.57)]);
    // Shows the chosen name, not the neighborhood the service returns.
    expect(find.text('24° en Medellín'), findsOneWidget);
    expect(find.text('Barrio'), findsNothing);
    // The API text is normalized and comes with a tip.
    expect(find.text('Nublado. Calor: ropa fresca y transpirable.'), findsOneWidget);
    // A single title at the top.
    expect(find.text('¿Qué me pongo hoy?'), findsOneWidget);
    expect(find.text('Estilista'), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('searching and choosing a city changes the weather and is remembered', (tester) async {
    await pumpScreen(tester, saved: medellin);

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Cali ');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(weather.searches, ['Cali']);

    await tester.tap(find.text('Cali'));
    await tester.pumpAndSettle();

    expect(find.text('24° en Cali'), findsOneWidget);
    expect(weather.requests.last, (3.45, -76.53));
    expect(jsonDecode(preferences.getString('weather_city')!)['name'], 'Cali');
  }, semanticsEnabled: false);

  testWidgets('does not search with fewer than two letters', (tester) async {
    await pumpScreen(tester, saved: medellin);

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'C');
    await tester.pump(const Duration(milliseconds: 500));

    expect(weather.searches, isEmpty);
  }, semanticsEnabled: false);

  testWidgets("the outfit is generated with the chosen city's weather", (tester) async {
    await pumpScreen(tester, saved: medellin);

    await tester.tap(find.text('Armar mi outfit'));
    await tester.pumpAndSettle();

    expect(outfits.requested, (6.24, -75.57));
  }, semanticsEnabled: false);

  testWidgets('without a city it asks for one and does not allow generating', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Elegir ciudad'), findsOneWidget);
    expect(find.textContaining('Elige tu ciudad'), findsOneWidget);
    expect(weather.requests, isEmpty);
    expect(mainButton(tester).onPressed, isNull);
  }, semanticsEnabled: false);

  testWidgets('the search no longer offers the phone location', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Elegir ciudad'));
    await tester.pumpAndSettle();

    expect(find.text('Usar mi ubicación actual'), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('shows the garments not worn lately', (tester) async {
    await pumpScreen(tester, saved: medellin);

    expect(find.text('Lo que no te has puesto últimamente'), findsOneWidget);
    expect(find.bySemanticsLabel('Blusa 1'), findsOneWidget);
  });

  testWidgets('an empty closet invites adding garments and does not allow generating', (tester) async {
    await pumpScreen(tester, saved: medellin, closet: []);

    expect(find.text('Agrega tus primeras prendas'), findsOneWidget);
    expect(find.text('Agregar prendas'), findsOneWidget);
    expect(mainButton(tester).onPressed, isNull);
  }, semanticsEnabled: false);
}
