import '../../budgets/models/budget.dart';
import '../../categories/models/category.dart';
import '../../transactions/models/money_transaction.dart';

/// Expenses of one category inside a month.
class CategoryReportRow {
  const CategoryReportRow({
    required this.categoryId,
    required this.name,
    required this.nameFr,
    required this.iconCode,
    required this.colorValue,
    required this.total,
    required this.count,
  });

  final String categoryId;
  final String name;
  final String nameFr;
  final int iconCode;
  final int colorValue;
  final int total;
  final int count;
}

/// Everything the monthly report / exports need, computed in pure Dart.
class MonthlyReport {
  const MonthlyReport({
    required this.monthKey,
    required this.income,
    required this.expense,
    required this.operationsCount,
    required this.byCategory,
  });

  final String monthKey;

  /// Sum of incomes (transfers excluded).
  final int income;

  /// Sum of expenses (transfers excluded).
  final int expense;

  /// `income - expense`.
  int get net => income - expense;

  final int operationsCount;

  /// Expense breakdown, biggest first.
  final List<CategoryReportRow> byCategory;

  bool get isEmpty => income == 0 && expense == 0 && operationsCount == 0;
}

/// Builds the report of [monthKey] from raw operations + category metadata.
///
/// Only non-transfer operations count; salary is included in [income].
MonthlyReport buildMonthlyReport({
  required List<MoneyTransaction> transactions,
  required List<Category> categories,
  required String monthKey,
}) {
  final inMonth = <MoneyTransaction>[
    for (final txn in transactions)
      if (Budget.monthKeyOf(txn.date) == monthKey) txn,
  ];

  var income = 0;
  var expense = 0;
  final byCategoryId = <String, int>{};
  final countByCategoryId = <String, int>{};

  for (final txn in inMonth) {
    if (txn.isTransfer) continue;
    if (txn.isIncome) {
      income += txn.amount;
    } else {
      expense += txn.amount;
      final key = txn.categoryId ?? '';
      byCategoryId[key] = (byCategoryId[key] ?? 0) + txn.amount;
      countByCategoryId[key] = (countByCategoryId[key] ?? 0) + 1;
    }
  }

  final rows = <CategoryReportRow>[];
  byCategoryId.forEach((categoryId, total) {
    Category? category;
    for (final c in categories) {
      if (c.id == categoryId) category = c;
    }
    rows.add(
      CategoryReportRow(
        categoryId: categoryId,
        name: category?.nameAr ?? '',
        nameFr: category?.nameFr ?? '',
        iconCode: category?.iconCode ?? 0xe5d3,
        colorValue: category?.colorValue ?? 0xFF00873D,
        total: total,
        count: countByCategoryId[categoryId] ?? 0,
      ),
    );
  });
  rows.sort((a, b) => b.total.compareTo(a.total));

  return MonthlyReport(
    monthKey: monthKey,
    income: income,
    expense: expense,
    operationsCount: inMonth.length,
    byCategory: rows,
  );
}
