import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/goal.dart';

/// All goals, newest first.
final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<Goal>>.value(const []);
  return ref.watch(goalRepositoryProvider).watch(uid);
});

final goalsOrNullProvider = Provider<List<Goal>>(
  (ref) => ref.watch(goalsProvider).valueOrNull ?? const [],
);

/// Goals still short of their target, best progress first.
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  final goals = [
    for (final g in ref.watch(goalsOrNullProvider))
      if (!g.isCompleted) g,
  ];
  goals.sort((a, b) => b.progress.compareTo(a.progress));
  return goals;
});

/// Seasonal preparation goals (shown on the seasonal screen).
final seasonalGoalsProvider = Provider<List<Goal>>((ref) {
  return [
    for (final g in ref.watch(goalsOrNullProvider))
      if (g.kind == GoalKind.seasonal) g,
  ];
});
