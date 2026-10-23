import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../debts/providers/debts_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../subscriptions/providers/subscriptions_providers.dart';
import '../../transactions/providers/transactions_providers.dart';
import '../domain/dashboard_calculator.dart';

/// Aggregates settings, period transactions, subscriptions and debts into one
/// [AsyncValue] so the dashboard always has a proper loading / error / data
/// state.
final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final periodAsync = ref.watch(periodTransactionsProvider);
  final previousAsync = ref.watch(previousPeriodTransactionsProvider);
  final debtsAsync = ref.watch(debtsProvider);
  final subscriptionsDue = ref.watch(subscriptionsDueTotalProvider);
  final now = ref.watch(nowProvider);

  final values = <AsyncValue<Object?>>[
    settingsAsync,
    periodAsync,
    previousAsync,
    debtsAsync,
  ];

  for (final value in values) {
    if (value.isLoading) return const AsyncValue.loading();
  }
  for (final value in values) {
    if (value.hasError) {
      return AsyncValue<DashboardData>.error(
        value.error!,
        value.stackTrace ?? StackTrace.current,
      );
    }
  }

  final settings = settingsAsync.valueOrNull;
  if (settings == null) return const AsyncValue.loading();

  return AsyncValue.data(
    buildDashboard(
      now: now,
      settings: settings,
      periodTransactions: periodAsync.valueOrNull ?? const [],
      previousTransactions: previousAsync.valueOrNull ?? const [],
      debts: debtsAsync.valueOrNull ?? const [],
      unpaidSubscriptionsDue: subscriptionsDue,
    ),
  );
});

/// Refreshes every dashboard input (pull to refresh) and re-reads "now".
Future<void> refreshDashboard(WidgetRef ref) async {
  ref.read(nowProvider.notifier).state = DateTime.now();
  ref.invalidate(periodTransactionsProvider);
  ref.invalidate(previousPeriodTransactionsProvider);
  ref.invalidate(debtsProvider);
  ref.invalidate(subscriptionsProvider);
  ref.invalidate(settingsProvider);
}
