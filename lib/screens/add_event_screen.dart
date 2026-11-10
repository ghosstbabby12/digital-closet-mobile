import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../repositories/outfit_repository.dart';
import '../state/city_provider.dart';
import '../state/outfit_provider.dart';
import '../widgets/city_search_sheet.dart';
import '../widgets/primary_button.dart';

/// Anota un evento en un día del calendario y le pide al Estilista el outfit.
class AddEventScreen extends ConsumerStatefulWidget {
  final DateTime day;

  const AddEventScreen({super.key, required this.day});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _titleController = TextEditingController();
  String _occasion = occasionOptions.first;
  bool _generating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final title = _titleController.text.trim();
    final city = ref.read(selectedCityProvider);
    if (title.isEmpty || city == null) return;

    setState(() => _generating = true);
    try {
      final outfit = await ref
          .read(outfitRepositoryProvider)
          .generate(occasion: _occasion, lat: city.lat, lon: city.lon, eventTitle: title, eventDate: widget.day);
      ref.invalidate(outfitHistoryProvider);
      if (!mounted) return;
      // Se reemplaza esta pantalla por el resultado: al cerrarlo se vuelve al calendario.
      context.pushReplacement('/outfit-result', extra: outfit);
    } catch (error) {
      if (!mounted) return;
      setState(() => _generating = false);
      final message = error is ApiException ? error.message : 'Ocurrió un error inesperado. Intenta de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dayName = DateFormat("EEEE, d 'de' MMMM", 'es').format(widget.day);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo evento')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('${dayName[0].toUpperCase()}${dayName.substring(1)}', style: textTheme.titleLarge),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre del evento', hintText: 'Ej. Boda de Ana'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text('Ocasión', style: textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: occasionOptions.map((occasion) {
                final selected = occasion == _occasion;
                return ChoiceChip(
                  label: Text('${occasion[0].toUpperCase()}${occasion.substring(1)}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _occasion = occasion),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(city?.name ?? 'Elige tu ciudad'),
              subtitle: const Text('El Estilista usa el clima actual de esta ciudad.'),
              trailing: TextButton(
                onPressed: () => showCitySearchSheet(context),
                child: Text(city == null ? 'Elegir' : 'Cambiar'),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Generar outfit para el evento',
              loading: _generating,
              onPressed: _titleController.text.trim().isEmpty || city == null ? null : _generate,
            ),
          ],
        ),
      ),
    );
  }
}
