import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_exception.dart';
import '../core/image_url.dart';
import '../models/look.dart';
import '../repositories/look_repository.dart';
import '../widgets/primary_button.dart';

/// Galería de los looks generados con IA.
class LooksScreen extends ConsumerWidget {
  const LooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final looks = ref.watch(looksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis looks')),
      body: looks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('No se pudieron cargar tus looks:\n$error', textAlign: TextAlign.center)),
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aún no tienes looks. En el probador, ponte unas prendas y toca "Ver cómo me queda".',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => LookScreen(look: items[index])),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Image.network(fullImageUrl(items[index].imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Un look a pantalla completa, con opción de borrarlo.
class LookScreen extends ConsumerWidget {
  final Look look;

  const LookScreen({super.key, required this.look});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar este look?'),
        content: const Text('Se borrará la imagen. Tus prendas no se tocan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(lookRepositoryProvider).delete(look.id);
      ref.invalidate(looksProvider);
      if (context.mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("d 'de' MMMM, HH:mm", 'es').format(look.createdAt.toLocal())),
        actions: [
          IconButton(
            tooltip: 'Borrar look',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Image.network(
                      fullImageUrl(look.imageUrl),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('No se pudo mostrar la imagen.')),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Listo', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
