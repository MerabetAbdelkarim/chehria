import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/pay_period.dart';
import '../../../core/providers/core_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/subscription.dart';

/// Every subscription of the signed-in user (due date ordered).
final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<Subscription>>.value(const []);
  return ref.watch(subscriptionRepositoryProvider).watch(uid);
});

final subscriptionsOrNullProvider = Provider<List<Subscription>>(
  (ref) => ref.watch(subscriptionsProvider).valueOrNull ?? const [],
);

/// Only the bills that are switched on.
final activeSubscriptionsProvider = Provider<List<Subscription>>(
  (ref) =>
      ref.watch(subscriptionsOrNullProvider).where((s) => s.isActive).toList(),
);

/// Active bills falling due before the next pay day (dashboard input).
final subscriptionsDueProvider = Provider<List<Subscription>>((ref) {
  final settings = ref.watch(settingsOrNullProvider);
  final now = ref.watch(nowProvider);
  if (settings == null) return const [];
  final end = PayPeriodCalculator.of(now: now, payday: settings.payday).end;
  return ref
      .watch(activeSubscriptionsProvider)
      .where((s) => s.dueBefore(end))
      .toList();
});

/// Their total, subtracted from the remaining amount on the dashboard.
final subscriptionsDueTotalProvider = Provider<int>((ref) {
  var total = 0;
  for (final s in ref.watch(subscriptionsDueProvider)) {
    total += s.amount;
  }
  return total;
});
