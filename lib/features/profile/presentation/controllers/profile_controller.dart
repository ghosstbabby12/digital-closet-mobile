import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:closet_ai/features/profile/data/profile_repository.dart';
import 'package:closet_ai/features/profile/domain/profile.dart';

/// The user's profile. Discarded on sign-out (and when the account changes).
final profileProvider = FutureProvider.autoDispose<Profile>((ref) {
  ref.watch(authProvider.select((auth) => auth.user?.id));
  return ref.read(profileRepositoryProvider).fetch();
});
