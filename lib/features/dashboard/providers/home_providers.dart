import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/pay_period.dart';
import '../../../core/providers/core_providers.dart';
import '../../budgets/domain/budget_status.dart';
import '../../budgets/models/budget.dart';
import '../../budgets/providers/budgets_providers.dart';
import '../../debts/models/debt.dart';
import '../../debts/providers/debts_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../subscriptions/models/subscription.dart';
import '../../subscriptions/providers/subscriptions_providers.dart';
import '../../transactions/models/money_transaction.dart';

/// One thing to pay before the next pay day: a bill or a debt I owe.
class BeforePaydayItem {
  const BeforePaydayItem.bill(Subscription this.subscription) : debt = null;

  const BeforePaydayItem.debt(Debt this.debt) : subscription = null;

  final Subscription? subscription;
  final Debt? debt;

  bool get isBill => subscription != null;
  String get name => subscription?.name ?? debt!.person;
  int get dueAmount => subscription?.amount ?? debt!.remaining;
  DateTime get dueDate => subscription?.nextDueDate ?? debt!.dueDate!;
}

/// Bills and debts I owe that fall due before the next pay day, soonest
/// first. Their total is what the dashboard already subtracts.
final beforePaydayProvider = Provider<List<BeforePaydayItem>>((ref) {
  final settings = ref.watch(settingsOrNullProvider);
  if (settings == null) return const [];
  final now = ref.watch(nowProvider);
  final end = PayPeriodCalculator.of(
    now: now,
    payday: settings.payday.clamp(1, 31),
  ).end;

  final items = [
    for (final sub in ref.watch(subscriptionsDueProvider))
      BeforePaydayItem.bill(sub),
    for (final debt in ref.watch(debtsDueBeforeProvider(end)))
      if (debt.remaining > 0 && debt.dueDate != null)
        BeforePaydayItem.debt(debt),
  ];
  items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return items;
});

/// Budgets of the **current** calendar month (independent of the month
/// picked on the budgets screen).
final _currentMonthBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final uid = ref.watch(uidProvider);
  final month = Budget.monthKeyOf(ref.watch(nowProvider));
  if (uid == null) return Stream<List<Budget>>.value(const []);
  return ref.watch(budgetRepositoryProvider).watchMonth(uid, month);
});

final _currentMonthTransactionsProvider =
    StreamProvider<List<MoneyTransaction>>((ref) {
      final uid = ref.watch(uidProvider);
      final month = Budget.monthKeyOf(ref.watch(nowProvider));
      if (uid == null) return Stream<List<MoneyTransaction>>.value(const []);
      return ref
          .watch(transactionRepositoryProvider)
          .watchRange(uid, Budget.monthStart(month), Budget.monthEnd(month));
    });

/// This month's budgets at 80 % or more of their ceiling, worst first.
final budgetAlertsProvider = Provider<List<BudgetRow>>((ref) {
  final budgets =
      ref.watch(_currentMonthBudgetsProvider).valueOrNull ?? const [];
  if (budgets.isEmpty) return const [];
  final txns =
      ref.watch(_currentMonthTransactionsProvider).valueOrNull ?? const [];

  final spent = <String, int>{};
  for (final t in txns) {
    if (!t.isExpense || t.categoryId == null) continue;
    spent[t.categoryId!] = (spent[t.categoryId!] ?? 0) + t.amount;
  }

  final rows = [
    for (final b in budgets)
      BudgetRow(budget: b, spent: spent[b.categoryId] ?? 0),
  ].where((r) => r.level != BudgetLevel.ok).toList();
  rows.sort((a, b) => b.ratio.compareTo(a.ratio));
  return rows;
});

/// Money owed to me for more than [AppConstants.oldDebtDays] days.
final oldDebtsProvider = Provider<List<Debt>>((ref) {
  final now = ref.watch(nowProvider);
  return ref.watch(owedToMeDebtsProvider).where((d) => d.isOld(now)).toList();
});
