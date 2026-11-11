import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/widgets/confirm_dialog.dart';
import 'package:closet_ai/core/widgets/error_snackbar.dart';
import 'package:closet_ai/core/widgets/primary_button.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:closet_ai/features/closet/presentation/garment_labels.dart';
import 'package:closet_ai/features/closet/presentation/widgets/garment_details.dart';
import 'package:closet_ai/features/closet/presentation/widgets/garment_form_fields.dart';

/// View, edit and delete a garment.
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

  Garment? _garment() =>
      ref.watch(closetProvider).valueOrNull?.where((garment) => garment.id == widget.garmentId).firstOrNull;

  void _startEditing(Garment garment) {
    _nameController.text = garment.name;
    _colorController.text = garment.color;
    setState(() {
      _category = garment.category;
      _warmth = garment.warmth;
      _editing = true;
    });
  }

  Future<void> _busyWhile(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(Garment garment) => _busyWhile(() async {
    await ref
        .read(closetProvider.notifier)
        .updateGarment(
          garment,
          name: _nameController.text.trim(),
          color: _colorController.text.trim(),
          category: _category,
          warmth: _warmth,
        );
    if (mounted) setState(() => _editing = false);
  });

  Future<void> _delete(Garment garment) async {
    final confirmed = await confirmDestructive(
      context,
      title: '¿Borrar esta prenda?',
      message: 'Se borrará "${garment.displayName}" con su foto. No se puede deshacer.',
    );
    if (!confirmed || !mounted) return;
    await _busyWhile(() async {
      await ref.read(closetProvider.notifier).removeGarment(garment.id);
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final garment = _garment();
    if (garment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Esta prenda ya no está en tu clóset.')),
      );
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
            GarmentPhoto(garment: garment),
            const SizedBox(height: 20),
            if (_editing) ..._form(garment) else GarmentDetails(garment: garment),
          ],
        ),
      ),
    );
  }

  List<Widget> _form(Garment garment) => [
    GarmentFormFields(
      nameController: _nameController,
      colorController: _colorController,
      category: _category,
      warmth: _warmth,
      onCategoryChanged: (value) => setState(() => _category = value),
      onWarmthChanged: (value) => setState(() => _warmth = value),
    ),
    const SizedBox(height: 24),
    PrimaryButton(label: 'Guardar cambios', loading: _busy, onPressed: () => _save(garment)),
    const SizedBox(height: 8),
    TextButton(onPressed: _busy ? null : () => setState(() => _editing = false), child: const Text('Cancelar')),
  ];
}
