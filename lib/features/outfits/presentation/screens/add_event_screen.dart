import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:closet_ai/features/weather/presentation/controllers/city_controller.dart';
import 'package:closet_ai/features/weather/presentation/widgets/city_search_sheet.dart';
import 'package:closet_ai/core/widgets/primary_button.dart';
import 'package:closet_ai/features/outfits/domain/occasion.dart';
import 'package:closet_ai/core/utils/text.dart';
import 'package:closet_ai/core/widgets/error_snackbar.dart';
import 'package:closet_ai/features/outfits/presentation/controllers/outfit_actions.dart';

/// Adds an event to a calendar day and asks the stylist for its outfit.
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
          .read(outfitActionsProvider)
          .planEvent(title: title, day: widget.day, occasion: _occasion, city: city);
      if (!mounted) return;
      // This screen is replaced by the result: closing it goes back to the calendar.
      context.pushReplacement('/outfit-result', extra: outfit);
    } catch (error) {
      if (!mounted) return;
      setState(() => _generating = false);
      showErrorSnackBar(context, error);
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
            Text(capitalized(dayName), style: textTheme.titleLarge),
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
                  label: Text(capitalized(occasion)),
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
