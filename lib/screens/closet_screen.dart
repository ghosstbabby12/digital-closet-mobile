import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../state/closet_provider.dart';
import '../widgets/garment_card.dart';
import '../widgets/screen_header.dart';

class ClosetScreen extends ConsumerWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garmentsAsync = ref.watch(closetProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Mi clóset',
            actions: [
              HeaderIconButton(
                icon: Icons.add,
                tooltip: 'Agregar prenda',
                onPressed: () => context.push('/add-garment'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(closetProvider.notifier).load(),
              child: garmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text('No se pudo cargar tu clóset:\n$error', textAlign: TextAlign.center)),
                  ],
                ),
                data: (garments) {
                  if (garments.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Tu clóset está vacío. Toca "+" para subir la foto de tu primera prenda.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, floatingNavClearance),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: garments.length,
                    itemBuilder: (context, index) {
                      final garment = garments[index];
                      return GarmentCard(
                        garment: garment,
                        onDelete: () => ref.read(closetProvider.notifier).removeGarment(garment.id),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
