import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../models/garment.dart';
import '../repositories/garment_repository.dart';
import '../state/closet_provider.dart';
import '../widgets/primary_button.dart';

class AddGarmentScreen extends ConsumerStatefulWidget {
  final ImagePicker? picker;

  const AddGarmentScreen({super.key, this.picker});

  @override
  ConsumerState<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends ConsumerState<AddGarmentScreen> {
  final _colorController = TextEditingController();
  final _nameController = TextEditingController();
  GarmentCategory _category = GarmentCategory.top;
  WarmthLevel _warmth = WarmthLevel.medium;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _submitting = false;
  String? _error;
  bool _categoryChosen = false;
  bool _warmthChosen = false;
  bool _analyzing = false;
  String? _autofillStatus;
  // Identifica el último análisis, para ignorar el de una foto ya reemplazada.
  int _analysisId = 0;

  @override
  void dispose() {
    _colorController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await (widget.picker ?? ImagePicker()).pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
      _autofill(picked);
    }
  }

  /// Llena los datos desde la foto sin pisar lo que el usuario ya escribió o eligió.
  Future<void> _autofill(XFile image) async {
    final analysisId = ++_analysisId;
    setState(() {
      _analyzing = true;
      _autofillStatus = null;
    });
    String status;
    GarmentSuggestion? suggestion;
    try {
      suggestion = await ref.read(garmentRepositoryProvider).suggest(image);
      status = 'Revisa los datos antes de guardar.';
    } on ApiException catch (e) {
      status = '${e.message} Puedes llenar los datos a mano.';
    } catch (_) {
      status = 'No se pudo analizar la foto. Puedes llenar los datos a mano.';
    }
    if (!mounted || analysisId != _analysisId) return;
    setState(() {
      _analyzing = false;
      _autofillStatus = status;
      if (suggestion == null) return;
      if (_nameController.text.trim().isEmpty) _nameController.text = suggestion.name;
      if (_colorController.text.trim().isEmpty) _colorController.text = suggestion.color;
      if (!_categoryChosen) _category = suggestion.category;
      if (!_warmthChosen) _warmth = suggestion.warmth;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_image == null) {
      setState(() => _error = 'Agrega una foto de la prenda.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(closetProvider.notifier).addGarment(
            category: _category,
            color: _colorController.text.trim(),
            warmth: _warmth,
            name: _nameController.text.trim(),
            image: _image!,
          );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva prenda')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            const Text('Toca para tomar o elegir una foto'),
                          ],
                        ),
                      )
                    : Image.memory(_imageBytes!, fit: BoxFit.contain, width: double.infinity),
              ),
            ),
            const SizedBox(height: 10),
            if (_analyzing)
              const Row(
                children: [
                  SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Completando los datos...')),
                ],
              )
            else if (_autofillStatus != null)
              Text(_autofillStatus!)
            else
              Text(
                'Para llenar los datos solos, la foto se envía a Google Gemini, y Google puede '
                'usarla para mejorar sus productos. Usa fotos de la prenda sola, sin personas.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre (opcional)'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<GarmentCategory>(
              // La clave recrea el campo cuando el autocompletado cambia el valor.
              key: ValueKey(_category),
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: GarmentCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (value) => setState(() {
                _category = value!;
                _categoryChosen = true;
              }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<WarmthLevel>(
              key: ValueKey(_warmth),
              initialValue: _warmth,
              decoration: const InputDecoration(labelText: 'Nivel de abrigo'),
              items: WarmthLevel.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: (value) => setState(() {
                _warmth = value!;
                _warmthChosen = true;
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(label: 'Guardar prenda', loading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
