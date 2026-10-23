import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../transactions/models/money_transaction.dart';
import '../domain/budget_status.dart';
import '../models/budget.dart';

/// Month currently shown on the budgets/reports screens (`YYYY-MM`).
final selectedMonthProvider = StateProvider<String>(
  (ref) => Budget.monthKeyOf(DateTime.now()),
);

/// Budgets of the selected month.
final monthBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final uid = ref.watch(uidProvider);
  final month = ref.watch(selectedMonthProvider);
  if (uid == null) return Stream<List<Budget>>.value(const []);
  return ref.watch(budgetRepositoryProvider).watchMonth(uid, month);
});

/// Operations of the selected calendar month.
final monthTransactionsProvider = StreamProvider<List<MoneyTransaction>>((ref) {
  final uid = ref.watch(uidProvider);
  final month = ref.watch(selectedMonthProvider);
  if (uid == null) return Stream<List<MoneyTransaction>>.value(const []);
  return ref
      .watch(transactionRepositoryProvider)
      .watchRange(uid, Budget.monthStart(month), Budget.monthEnd(month));
});

/// Expenses of the selected month grouped by category.
final spentByCategoryProvider = Provider<Map<String, int>>((ref) {
  final txns = ref.watch(monthTransactionsProvider).valueOrNull ?? const [];
  final result = <String, int>{};
  for (final txn in txns) {
    if (!txn.isExpense || txn.categoryId == null) continue;
    result[txn.categoryId!] = (result[txn.categoryId!] ?? 0) + txn.amount;
  }
  return result;
});

/// One row per budget: the ceiling plus what the month spent so far.
class BudgetRow {
  const BudgetRow({required this.budget, required this.spent});

  final Budget budget;
  final int spent;

  int get remaining => budgetRemaining(limit: budget.limit, spent: spent);
  BudgetLevel get level => budgetLevel(limit: budget.limit, spent: spent);
  double get ratio => budgetRatio(limit: budget.limit, spent: spent);
}

/// Budget rows of the selected month, worst levels first.
final budgetRowsProvider = Provider<List<BudgetRow>>((ref) {
  final budgets = ref.watch(monthBudgetsProvider).valueOrNull ?? const [];
  final spentByCategory = ref.watch(spentByCategoryProvider);

  final rows = [
    for (final budget in budgets)
      BudgetRow(budget: budget, spent: spentByCategory[budget.categoryId] ?? 0),
  ];
  rows.sort((a, b) {
    final byLevel = b.level.index.compareTo(a.level.index);
    if (byLevel != 0) return byLevel;
    return b.ratio.compareTo(a.ratio);
  });
  return rows;
});

/// How many budgets are over their ceiling (dashboard-style badge).
final exceededBudgetsProvider = Provider<int>((ref) {
  var count = 0;
  for (final row in ref.watch(budgetRowsProvider)) {
    if (row.level == BudgetLevel.exceeded) count++;
  }
  return count;
});
