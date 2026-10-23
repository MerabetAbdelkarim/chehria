import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/debt.dart';

/// Every debt of the signed-in user (both directions).
final debtsProvider = StreamProvider<List<Debt>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<Debt>>.value(const []);
  return ref.watch(debtRepositoryProvider).watch(uid);
});

final debtsOrNullProvider = Provider<List<Debt>>(
  (ref) => ref.watch(debtsProvider).valueOrNull ?? const [],
);

/// What other people owe me.
final owedToMeTotalProvider = Provider<int>((ref) {
  var total = 0;
  for (final debt in ref.watch(debtsOrNullProvider)) {
    if (debt.type == DebtType.owedToMe) total += debt.remaining;
  }
  return total;
});

/// What I owe to other people.
final iOweTotalProvider = Provider<int>((ref) {
  var total = 0;
  for (final debt in ref.watch(debtsOrNullProvider)) {
    if (debt.type == DebtType.iOwe) total += debt.remaining;
  }
  return total;
});

/// Only the debts I have to pay back.
final iOweDebtsProvider = Provider<List<Debt>>(
  (ref) => ref
      .watch(debtsOrNullProvider)
      .where((d) => d.type == DebtType.iOwe)
      .toList(),
);

/// Only the debts other people have to pay me back.
final owedToMeDebtsProvider = Provider<List<Debt>>(
  (ref) => ref
      .watch(debtsOrNullProvider)
      .where((d) => d.type == DebtType.owedToMe)
      .toList(),
);

/// Unpaid debts of either side falling due before the next pay day.
final debtsDueBeforeProvider = Provider.family<List<Debt>, DateTime>(
  (ref, limit) => ref
      .watch(debtsOrNullProvider)
      .where((d) => d.type == DebtType.iOwe && d.isDueBefore(limit))
      .toList(),
);
