import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/pay_period.dart';
import '../../../core/providers/core_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/money_transaction.dart';

/// The most recent operations (transactions screen).
final recentTransactionsProvider = StreamProvider<List<MoneyTransaction>>((
  ref,
) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<MoneyTransaction>>.value(const []);
  return ref.watch(transactionRepositoryProvider).watchRecent(uid);
});

/// Operations of the **current** pay period.
final periodTransactionsProvider = StreamProvider<List<MoneyTransaction>>((
  ref,
) {
  final uid = ref.watch(uidProvider);
  final settings = ref.watch(settingsOrNullProvider);
  final now = ref.watch(nowProvider);
  if (uid == null || settings == null) {
    return Stream<List<MoneyTransaction>>.value(const []);
  }
  final period = PayPeriodCalculator.of(
    now: now,
    payday: settings.payday.clamp(1, 31),
  );
  return ref
      .watch(transactionRepositoryProvider)
      .watchRange(uid, period.start, period.end);
});

/// Operations of the **previous** pay period (comparison on the dashboard).
final previousPeriodTransactionsProvider =
    StreamProvider<List<MoneyTransaction>>((ref) {
      final uid = ref.watch(uidProvider);
      final settings = ref.watch(settingsOrNullProvider);
      final now = ref.watch(nowProvider);
      if (uid == null || settings == null) {
        return Stream<List<MoneyTransaction>>.value(const []);
      }
      final period = PayPeriodCalculator.previous(
        now: now,
        payday: settings.payday.clamp(1, 31),
      );
      return ref
          .watch(transactionRepositoryProvider)
          .watchRange(uid, period.start, period.end);
    });
