import 'package:flutter/material.dart';

import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/closet/presentation/garment_labels.dart';

/// Name, color, category and warmth fields, shared by "Nueva prenda" and "Editar prenda".
class GarmentFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController colorController;
  final GarmentCategory category;
  final WarmthLevel warmth;
  final ValueChanged<GarmentCategory> onCategoryChanged;
  final ValueChanged<WarmthLevel> onWarmthChanged;

  const GarmentFormFields({
    super.key,
    required this.nameController,
    required this.colorController,
    required this.category,
    required this.warmth,
    required this.onCategoryChanged,
    required this.onWarmthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre (opcional)'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: colorController,
          decoration: const InputDecoration(labelText: 'Color'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<GarmentCategory>(
          // The key rebuilds the field when autofill changes the value.
          key: ValueKey(category),
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Categoría'),
          items: [for (final c in GarmentCategory.values) DropdownMenuItem(value: c, child: Text(c.label))],
          onChanged: (value) => onCategoryChanged(value!),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<WarmthLevel>(
          key: ValueKey(warmth),
          initialValue: warmth,
          decoration: const InputDecoration(labelText: 'Nivel de abrigo'),
          items: [for (final w in WarmthLevel.values) DropdownMenuItem(value: w, child: Text(w.label))],
          onChanged: (value) => onWarmthChanged(value!),
        ),
      ],
    );
  }
}
