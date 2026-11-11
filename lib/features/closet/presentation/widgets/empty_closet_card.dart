import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Invites the user to add their first garments.
class EmptyClosetCard extends StatelessWidget {
  const EmptyClosetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.checkroom_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text('Agrega tus primeras prendas', style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'El Estilista arma tus outfits con lo que tienes en el clóset. Empieza con 2 o 3 prendas.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => context.push('/add-garment'),
              icon: const Icon(Icons.add),
              label: const Text('Agregar prendas'),
            ),
          ],
        ),
      ),
    );
  }
}
