import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:closet_ai/core/network/api_exception.dart';
import 'package:closet_ai/core/widgets/error_snackbar.dart';
import 'package:closet_ai/core/widgets/photo_source_sheet.dart';
import 'package:closet_ai/core/widgets/retry_message.dart';
import 'package:closet_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:closet_ai/features/profile/domain/profile.dart';
import 'package:closet_ai/features/profile/presentation/controllers/avatar_controller.dart';
import 'package:closet_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:closet_ai/features/profile/presentation/screens/change_password_screen.dart';
import 'package:closet_ai/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:closet_ai/features/profile/presentation/widgets/activity_stats.dart';
import 'package:closet_ai/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:closet_ai/features/profile/presentation/widgets/profile_details_card.dart';

/// Account details, profile photo and a summary of the user's activity.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: ref
            .watch(profileProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => RetryMessage(
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

  Future<void> _guard(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  void _changeAvatar(BuildContext context, WidgetRef ref) {
    final avatar = ref.read(avatarControllerProvider.notifier);
    showPhotoSourceSheet(
      context,
      onPick: (source) => _guard(context, () async {
        final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 800, maxHeight: 800);
        if (picked != null) await avatar.upload(picked);
      }),
      removeLabel: 'Quitar foto',
      onRemove: profile.avatarUrl == null ? null : () => _guard(context, avatar.remove),
    );
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    final since = DateFormat("d 'de' MMMM 'de' y", 'es').format(profile.createdAt.toLocal());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Center(
          child: ProfileAvatar(
            profile: profile,
            busy: ref.watch(avatarControllerProvider),
            onTap: () => _changeAvatar(context, ref),
          ),
        ),
        const SizedBox(height: 16),
        Text(profile.displayName, textAlign: TextAlign.center, style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Miembro desde el $since', textAlign: TextAlign.center, style: textTheme.bodyMedium),
        const SizedBox(height: 24),
        ProfileDetailsCard(profile: profile),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar datos'),
          onPressed: () => _open(context, EditProfileScreen(profile: profile)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline),
          label: const Text('Cambiar contraseña'),
          onPressed: () => _open(context, const ChangePasswordScreen()),
        ),
        const SizedBox(height: 24),
        ActivityStats(profile: profile),
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
          leading: Icon(Icons.logout, color: error),
          title: Text(
            'Cerrar sesión',
            style: TextStyle(color: error, fontWeight: FontWeight.w600),
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
