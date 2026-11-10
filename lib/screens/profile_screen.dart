import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/api_exception.dart';
import '../core/image_url.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import '../state/auth_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

/// Datos de la cuenta, foto de perfil y resumen de la actividad del usuario.
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

class _ProfileView extends ConsumerStatefulWidget {
  final Profile profile;

  const _ProfileView({required this.profile});

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  bool _avatarBusy = false;

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : 'Ocurrió un error inesperado. Intenta de nuevo.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeAvatar(Future<void> Function() action) async {
    setState(() => _avatarBusy = true);
    try {
      await action();
      ref.invalidate(profileProvider);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 800, maxHeight: 800);
    if (picked == null) return;
    await _changeAvatar(() => ref.read(profileRepositoryProvider).uploadAvatar(picked));
  }

  void _showAvatarOptions() {
    final hasAvatar = widget.profile.avatarUrl != null;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Quitar foto', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _changeAvatar(() => ref.read(profileRepositoryProvider).deleteAvatar());
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final since = DateFormat("d 'de' MMMM 'de' y", 'es').format(profile.createdAt.toLocal());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Center(
          child: Semantics(
            button: true,
            label: 'Cambiar foto de perfil',
            child: GestureDetector(
              onTap: _avatarBusy ? null : _showAvatarOptions,
              child: Stack(
                children: [
                  _Avatar(profile: profile, busy: _avatarBusy),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary,
                      child: Icon(Icons.photo_camera_outlined, size: 16, color: scheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(profile.displayName, textAlign: TextAlign.center, style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Miembro desde el $since', textAlign: TextAlign.center, style: textTheme.bodyMedium),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _InfoRow(icon: Icons.person_outline, label: 'Nombre', value: profile.name ?? 'Sin nombre'),
                _InfoRow(icon: Icons.mail_outline, label: 'Correo', value: profile.email),
                _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: profile.phone ?? 'Sin teléfono'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar datos'),
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditProfileScreen(profile: profile))),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline),
          label: const Text('Cambiar contraseña'),
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen())),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StatCard(value: profile.garmentCount, label: 'Prendas'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: profile.outfitCount, label: 'Outfits'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: profile.lookCount, label: 'Looks'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(profile.hasBodyPhoto ? Icons.check_circle_outline : Icons.accessibility_new_outlined),
          title: const Text('Foto para el probador'),
          subtitle: Text(profile.hasBodyPhoto ? 'Ya subiste tu foto.' : 'Aún no has subido tu foto.'),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.logout, color: scheme.error),
          title: Text(
            'Cerrar sesión',
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.pop(context);
            ref.read(authProvider.notifier).logout();
          },
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final Profile profile;
  final bool busy;

  const _Avatar({required this.profile, required this.busy});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = Text(
      profile.displayName.characters.first.toUpperCase(),
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.onPrimaryContainer),
    );
    return SizedBox(
      width: 96,
      height: 96,
      child: ClipOval(
        child: ColoredBox(
          color: scheme.primaryContainer,
          child: busy
              ? const Center(child: CircularProgressIndicator())
              : profile.avatarUrl == null
              ? Center(child: initial)
              : Image.network(
                  fullImageUrl(profile.avatarUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(child: initial),
                ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
