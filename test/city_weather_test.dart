import 'dart:convert';

import 'package:closet_ai/core/api_exception.dart';
import 'package:closet_ai/models/outfit.dart';
import 'package:closet_ai/models/weather.dart';
import 'package:closet_ai/repositories/outfit_repository.dart';
import 'package:closet_ai/repositories/weather_repository.dart';
import 'package:closet_ai/screens/generate_outfit_screen.dart';
import 'package:closet_ai/state/theme_provider.dart';
import 'package:closet_ai/state/weather_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final medellin = City(name: 'Medellín', state: 'Antioquia', country: 'CO', lat: 6.24, lon: -75.57);
final cali = City(name: 'Cali', state: 'Valle del Cauca', country: 'CO', lat: 3.45, lon: -76.53);

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

class FakeOutfits extends OutfitRepository {
  FakeOutfits() : super(Dio());
  (double, double)? requested;

  @override
  Future<Outfit> generate({required String occasion, required double lat, required double lon}) async {
    requested = (lat, lon);
    throw ApiException('detenido en la prueba');
  }
}

void main() {
  late FakeWeather weather;
  late FakeOutfits outfits;
  late SharedPreferences preferences;

  Future<void> pumpScreen(WidgetTester tester, {City? saved}) async {
    SharedPreferences.setMockInitialValues({
      if (saved != null) 'weather_city': jsonEncode(saved.toJson()),
    });
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
          // Sin GPS en las pruebas: si se pide la ubicación, falla con un mensaje.
          currentPositionProvider.overrideWith((ref) => throw Exception('Sin GPS en la prueba')),
        ],
        child: const MaterialApp(home: Scaffold(body: GenerateOutfitScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('usa la ciudad guardada para el clima', (tester) async {
    await pumpScreen(tester, saved: medellin);

    expect(find.text('Medellín, Antioquia, CO'), findsOneWidget);
    expect(weather.requests, [(6.24, -75.57)]);
    // Muestra el nombre elegido, no el barrio que devuelve el servicio.
    expect(find.text('Medellín'), findsOneWidget);
    expect(find.text('Barrio'), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('buscar y elegir una ciudad cambia el clima y se recuerda', (tester) async {
    await pumpScreen(tester, saved: medellin);

    await tester.tap(find.text('Cambiar ciudad'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Cali ');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(weather.searches, ['Cali']);

    await tester.tap(find.text('Cali'));
    await tester.pumpAndSettle();

    expect(find.text('Cali, Valle del Cauca, CO'), findsOneWidget);
    expect(weather.requests.last, (3.45, -76.53));
    expect(jsonDecode(preferences.getString('weather_city')!)['name'], 'Cali');
  }, semanticsEnabled: false);

  testWidgets('no busca con menos de dos letras', (tester) async {
    await pumpScreen(tester, saved: medellin);

    await tester.tap(find.text('Cambiar ciudad'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'C');
    await tester.pump(const Duration(milliseconds: 500));

    expect(weather.searches, isEmpty);
  }, semanticsEnabled: false);

  testWidgets('el outfit se genera con el clima de la ciudad elegida', (tester) async {
    await pumpScreen(tester, saved: medellin);

    await tester.tap(find.text('Vestirme hoy'));
    await tester.pumpAndSettle();

    expect(outfits.requested, (6.24, -75.57));
  }, semanticsEnabled: false);

  testWidgets('volver a mi ubicación borra la ciudad guardada', (tester) async {
    await pumpScreen(tester, saved: medellin);

    await tester.tap(find.text('Cambiar ciudad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar mi ubicación actual'));
    await tester.pumpAndSettle();

    expect(find.text('Mi ubicación actual'), findsOneWidget);
    expect(preferences.getString('weather_city'), isNull);
    expect(find.textContaining('Sin GPS en la prueba'), findsOneWidget);
  }, semanticsEnabled: false);
}
