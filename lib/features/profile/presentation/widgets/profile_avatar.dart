import 'package:flutter/material.dart';

import 'package:closet_ai/core/network/image_url.dart';
import 'package:closet_ai/features/profile/domain/profile.dart';

/// Round profile photo (or the name's initial) with a camera badge to change it.
class ProfileAvatar extends StatelessWidget {
  final Profile profile;
  final bool busy;
  final VoidCallback onTap;

  const ProfileAvatar({super.key, required this.profile, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Cambiar foto de perfil',
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Stack(
          children: [
            SizedBox.square(
              dimension: 96,
              child: ClipOval(
                child: ColoredBox(color: scheme.primaryContainer, child: _photo(context)),
              ),
            ),
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
    );
  }

  Widget _photo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = Center(
      child: Text(
        profile.displayName.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.onPrimaryContainer),
      ),
    );
    if (busy) return const Center(child: CircularProgressIndicator());
    if (profile.avatarUrl == null) return initial;
    return Image.network(
      fullImageUrl(profile.avatarUrl!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => initial,
    );
  }
}
