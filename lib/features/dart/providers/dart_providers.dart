import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/dart_group.dart';

/// All dawras of the signed-in user.
final dartGroupsProvider = StreamProvider<List<DartGroup>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<DartGroup>>.value(const []);
  return ref.watch(dartRepositoryProvider).watch(uid);
});

final dartGroupsOrNullProvider = Provider<List<DartGroup>>(
  (ref) => ref.watch(dartGroupsProvider).valueOrNull ?? const [],
);

/// One dawra by id (live).
final dartGroupProvider = Provider.family<DartGroup?, String>((ref, id) {
  for (final group in ref.watch(dartGroupsOrNullProvider)) {
    if (group.id == id) return group;
  }
  return null;
});
