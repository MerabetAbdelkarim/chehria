import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

export '../../../core/providers/core_providers.dart'
    show authStateProvider, currentUserProvider, uidProvider;

/// Creates `users/{uid}` + seed data the first time a user signs in.
final ensureProfileProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  await ref.watch(bootstrapRepositoryProvider).ensureProfile(user);
});
