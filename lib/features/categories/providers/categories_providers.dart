import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/category.dart';

/// All categories of the signed-in user.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<Category>>.value(const []);
  return ref.watch(categoryRepositoryProvider).watch(uid);
});

final categoriesOrNullProvider = Provider<List<Category>>(
  (ref) => ref.watch(categoriesProvider).valueOrNull ?? const [],
);

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  for (final category in ref.watch(categoriesOrNullProvider)) {
    if (category.id == id) return category;
  }
  return null;
});
