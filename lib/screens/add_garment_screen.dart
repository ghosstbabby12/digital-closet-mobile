import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../core/app_theme.dart';
import '../models/garment.dart';
import '../state/closet_provider.dart';

class AddGarmentScreen extends ConsumerStatefulWidget {
  const AddGarmentScreen({super.key});

  @override
  ConsumerState<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends ConsumerState<AddGarmentScreen> {
  final _colorController = TextEditingController();
  final _nameController = TextEditingController();
  GarmentCategory _category = GarmentCategory.top;
  WarmthLevel _warmth = WarmthLevel.medium;
  File? _imageFile;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _colorController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
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
    if (_imageFile == null) {
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
            imageFile: _imageFile!,
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageFile == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo, size: 36, color: AppColors.inkSoft),
                            SizedBox(height: 8),
                            Text('Toca para tomar o elegir una foto'),
                          ],
                        ),
                      )
                    : Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
              ),
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
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: GarmentCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<WarmthLevel>(
              initialValue: _warmth,
              decoration: const InputDecoration(labelText: 'Nivel de abrigo'),
              items: WarmthLevel.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: (value) => setState(() => _warmth = value!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar prenda'),
            ),
          ],
        ),
      ),
    );
  }
}
