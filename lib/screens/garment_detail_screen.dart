import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../core/image_url.dart';
import '../models/garment.dart';
import '../state/closet_provider.dart';
import '../widgets/primary_button.dart';

/// Ver, editar y borrar una prenda del clóset.
class GarmentDetailScreen extends ConsumerStatefulWidget {
  final int garmentId;

  const GarmentDetailScreen({super.key, required this.garmentId});

  @override
  ConsumerState<GarmentDetailScreen> createState() => _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends ConsumerState<GarmentDetailScreen> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  late GarmentCategory _category;
  late WarmthLevel _warmth;
  bool _editing = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Garment? _garment() {
    final garments = ref.watch(closetProvider).valueOrNull ?? const <Garment>[];
    for (final garment in garments) {
      if (garment.id == widget.garmentId) return garment;
    }
    return null;
  }

  void _startEditing(Garment garment) {
    _nameController.text = garment.name;
    _colorController.text = garment.color;
    setState(() {
      _category = garment.category;
      _warmth = garment.warmth;
      _editing = true;
    });
  }

  void _showError(Object error) {
    final message = error is ApiException ? error.message : 'Ocurrió un error inesperado. Intenta de nuevo.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(Garment garment) async {
    setState(() => _busy = true);
    try {
      await ref.read(closetProvider.notifier).updateGarment(
            garment,
            name: _nameController.text.trim(),
            color: _colorController.text.trim(),
            category: _category,
            warmth: _warmth,
          );
      if (mounted) setState(() => _editing = false);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Garment garment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar esta prenda?'),
        content: Text(
          'Se borrará "${garment.name.isNotEmpty ? garment.name : garment.category.label}" con su foto. '
          'No se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(closetProvider.notifier).removeGarment(garment.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final garment = _garment();
    if (garment == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Esta prenda ya no está en tu clóset.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar prenda' : 'Prenda'),
        actions: [
          if (!_editing) ...[
            IconButton(
              tooltip: 'Editar prenda',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _busy ? null : () => _startEditing(garment),
            ),
            IconButton(
              tooltip: 'Borrar prenda',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : () => _delete(garment),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SizedBox(
                  height: 320,
                  child: Image.network(
                    fullImageUrl(garment.imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.checkroom, size: 48)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_editing) ..._form(garment) else ..._details(garment),
          ],
        ),
      ),
    );
  }

  List<Widget> _details(Garment garment) {
    final textTheme = Theme.of(context).textTheme;
    return [
      Text(garment.name.isNotEmpty ? garment.name : garment.category.label, style: textTheme.headlineMedium),
      const SizedBox(height: 16),
      _DetailRow(label: 'Categoría', value: garment.category.label),
      _DetailRow(label: 'Color', value: garment.color.isNotEmpty ? garment.color : 'Sin color'),
      _DetailRow(label: 'Nivel de abrigo', value: garment.warmth.label),
    ];
  }

  List<Widget> _form(Garment garment) {
    return [
      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre (opcional)')),
      const SizedBox(height: 14),
      TextField(controller: _colorController, decoration: const InputDecoration(labelText: 'Color')),
      const SizedBox(height: 14),
      DropdownButtonFormField<GarmentCategory>(
        initialValue: _category,
        decoration: const InputDecoration(labelText: 'Categoría'),
        items: GarmentCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
        onChanged: (value) => setState(() => _category = value!),
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<WarmthLevel>(
        initialValue: _warmth,
        decoration: const InputDecoration(labelText: 'Nivel de abrigo'),
        items: WarmthLevel.values.map((w) => DropdownMenuItem(value: w, child: Text(w.label))).toList(),
        onChanged: (value) => setState(() => _warmth = value!),
      ),
      const SizedBox(height: 24),
      PrimaryButton(label: 'Guardar cambios', loading: _busy, onPressed: () => _save(garment)),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : () => setState(() => _editing = false),
        child: const Text('Cancelar'),
      ),
    ];
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
