import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/pay_period.dart';
import '../../../core/providers/core_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/money_transaction.dart';

/// How many operations the history screen currently shows; grows one page
/// at a time ("load more") and resets when the screen is closed.
final transactionsLimitProvider = StateProvider.autoDispose<int>(
  (ref) => AppConstants.transactionsPageSize,
);

/// The most recent operations (transactions screen).
final recentTransactionsProvider =
    StreamProvider.autoDispose<List<MoneyTransaction>>((ref) {
      final uid = ref.watch(uidProvider);
      final limit = ref.watch(transactionsLimitProvider);
      if (uid == null) return Stream<List<MoneyTransaction>>.value(const []);
      return ref
          .watch(transactionRepositoryProvider)
          .watchRecent(uid, limit: limit);
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
