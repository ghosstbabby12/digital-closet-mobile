import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/weather.dart';
import '../repositories/weather_repository.dart';
import '../state/city_provider.dart';

void showCitySearchSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _CitySearchSheet(),
  );
}

class _CitySearchSheet extends ConsumerStatefulWidget {
  const _CitySearchSheet();

  @override
  ConsumerState<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends ConsumerState<_CitySearchSheet> {
  Timer? _debounce;
  List<City> _results = [];
  bool _searching = false;
  String? _message;
  // Identifica la última búsqueda, para ignorar respuestas que llegan tarde.
  int _searchId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.length < 2) {
      _searchId++;
      setState(() {
        _results = [];
        _searching = false;
        _message = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    final searchId = ++_searchId;
    setState(() {
      _searching = true;
      _message = null;
    });
    List<City> results = [];
    String? message;
    try {
      results = await ref.read(weatherRepositoryProvider).searchCities(query);
      if (results.isEmpty) message = 'No encontramos esa ciudad. Revisa cómo está escrita.';
    } on ApiException catch (e) {
      message = e.message;
    } catch (_) {
      message = 'No se pudo buscar la ciudad. Intenta de nuevo.';
    }
    if (!mounted || searchId != _searchId) return;
    setState(() {
      _searching = false;
      _results = results;
      _message = message;
    });
  }

  void _choose(City city) {
    ref.read(selectedCityProvider.notifier).select(city);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ciudad', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 14),
                TextField(
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Buscar ciudad',
                    hintText: 'Ej.: Medellín, Cartagena, Madrid',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _onChanged,
                ),
                const SizedBox(height: 8),
                if (_searching) const LinearProgressIndicator(),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_message!, textAlign: TextAlign.center),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final city in _results)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_city_outlined),
                          title: Text(city.name),
                          subtitle: Text([if (city.state != null) city.state!, city.country].join(', ')),
                          onTap: () => _choose(city),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
