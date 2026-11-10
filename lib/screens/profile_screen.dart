import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_exception.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import '../state/auth_provider.dart';

/// Correo, fecha de registro y resumen de la actividad del usuario.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: error is ApiException ? error.message : 'No se pudo cargar tu perfil.',
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (profile) => RefreshIndicator(
            onRefresh: () => ref.refresh(profileProvider.future),
            child: _ProfileView(profile: profile),
          ),
        ),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  final Profile profile;

  const _ProfileView({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final since = DateFormat("d 'de' MMMM 'de' y", 'es').format(profile.createdAt.toLocal());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              profile.email.characters.first.toUpperCase(),
              style: textTheme.headlineMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(profile.email, textAlign: TextAlign.center, style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Miembro desde el $since', textAlign: TextAlign.center, style: textTheme.bodyMedium),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: _StatCard(value: profile.garmentCount, label: 'Prendas')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: profile.outfitCount, label: 'Outfits')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: profile.lookCount, label: 'Looks')),
          ],
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(profile.hasBodyPhoto ? Icons.check_circle_outline : Icons.person_outline),
          title: const Text('Foto para el probador'),
          subtitle: Text(profile.hasBodyPhoto ? 'Ya subiste tu foto.' : 'Aún no has subido tu foto.'),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.logout, color: scheme.error),
          title: Text('Cerrar sesión', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
          onTap: () {
            Navigator.pop(context);
            ref.read(authProvider.notifier).logout();
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('$value', style: textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
