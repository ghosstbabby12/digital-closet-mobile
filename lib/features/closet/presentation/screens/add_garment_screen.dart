import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/core/widgets/photo_source_sheet.dart';
import 'package:closet_ai/core/widgets/primary_button.dart';
import 'package:closet_ai/features/closet/data/garment_repository.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/controllers/closet_controller.dart';
import 'package:closet_ai/features/closet/presentation/widgets/autofill_status.dart';
import 'package:closet_ai/features/closet/presentation/widgets/garment_form_fields.dart';
import 'package:closet_ai/features/closet/presentation/widgets/photo_drop_zone.dart';

class AddGarmentScreen extends ConsumerStatefulWidget {
  final ImagePicker? picker;

  const AddGarmentScreen({super.key, this.picker});

  @override
  ConsumerState<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends ConsumerState<AddGarmentScreen> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  GarmentCategory _category = GarmentCategory.top;
  WarmthLevel _warmth = WarmthLevel.medium;
  bool _categoryChosen = false;
  bool _warmthChosen = false;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _submitting = false;
  String? _error;
  bool _analyzing = false;
  String? _autofillMessage;

  // Identifies the latest analysis, to ignore one for a photo that was already replaced.
  int _analysisId = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await (widget.picker ?? ImagePicker()).pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _image = picked;
      _imageBytes = bytes;
    });
    _autofill(picked);
  }

  /// Fills the fields from the photo without overwriting what the user already typed or chose.
  Future<void> _autofill(XFile image) async {
    final analysisId = ++_analysisId;
    setState(() {
      _analyzing = true;
      _autofillMessage = null;
    });
    GarmentSuggestion? suggestion;
    String message;
    try {
      suggestion = await ref.read(garmentRepositoryProvider).suggest(image);
      message = 'Revisa los datos antes de guardar.';
    } on ApiException catch (e) {
      message = '${e.message} Puedes llenar los datos a mano.';
    } catch (_) {
      message = 'No se pudo analizar la foto. Puedes llenar los datos a mano.';
    }
    if (!mounted || analysisId != _analysisId) return;
    setState(() {
      _analyzing = false;
      _autofillMessage = message;
      if (suggestion != null) _applySuggestion(suggestion);
    });
  }

  void _applySuggestion(GarmentSuggestion suggestion) {
    if (_nameController.text.trim().isEmpty) _nameController.text = suggestion.name;
    if (_colorController.text.trim().isEmpty) _colorController.text = suggestion.color;
    if (!_categoryChosen) _category = suggestion.category;
    if (!_warmthChosen) _warmth = suggestion.warmth;
  }

  Future<void> _submit() async {
    if (_image == null) return setState(() => _error = 'Agrega una foto de la prenda.');
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(closetProvider.notifier)
          .addGarment(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva prenda')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PhotoDropZone(
              imageBytes: _imageBytes,
              onTap: () => showPhotoSourceSheet(context, onPick: _pickImage),
            ),
            const SizedBox(height: 10),
            AutofillStatus(analyzing: _analyzing, message: _autofillMessage),
            const SizedBox(height: 20),
            GarmentFormFields(
              nameController: _nameController,
              colorController: _colorController,
              category: _category,
              warmth: _warmth,
              onCategoryChanged: (value) => setState(() {
                _category = value;
                _categoryChosen = true;
              }),
              onWarmthChanged: (value) => setState(() {
                _warmth = value;
                _warmthChosen = true;
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(label: 'Guardar prenda', loading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
