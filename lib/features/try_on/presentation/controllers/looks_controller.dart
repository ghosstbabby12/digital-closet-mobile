import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/try_on/data/look_repository.dart';
import 'package:closet_ai/features/try_on/domain/look.dart';

/// The user's AI-generated looks, newest first.
final looksProvider = FutureProvider.autoDispose<List<Look>>((ref) {
  return ref.read(lookRepositoryProvider).list();
});

final deleteLookProvider = Provider<Future<void> Function(int lookId)>((ref) {
  return (lookId) async {
    await ref.read(lookRepositoryProvider).delete(lookId);
    ref.invalidate(looksProvider);
  };
});
