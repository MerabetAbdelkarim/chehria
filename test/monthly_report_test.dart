import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/features/categories/models/category.dart';
import 'package:masarifi/features/reports/domain/monthly_report.dart';
import 'package:masarifi/features/transactions/models/money_transaction.dart';

MoneyTransaction expense(int amount, DateTime date, {String? categoryId}) =>
    MoneyTransaction(
      id: 'e${date.millisecondsSinceEpoch}$amount',
      type: TxnType.expense,
      amount: amount,
      date: date,
      categoryId: categoryId,
      accountId: 'acc_cash',
    );

MoneyTransaction income(int amount, DateTime date) => MoneyTransaction(
  id: 'i${date.millisecondsSinceEpoch}$amount',
  type: TxnType.income,
  amount: amount,
  date: date,
  categoryId: 'cat_salary',
  accountId: 'acc_cash',
  source: TxnSource.salary,
);

const food = Category(
  id: 'cat_food',
  nameAr: 'طعام',
  nameFr: 'Alimentation',
  iconCode: 0xe5d3,
  colorValue: 0xFF00873D,
);

const transport = Category(
  id: 'cat_transport',
  nameAr: 'نقل',
  nameFr: 'Transport',
  iconCode: 0xe532,
  colorValue: 0xFF1565C0,
);

void main() {
  final october = [
    expense(500, DateTime(2026, 10, 2), categoryId: 'cat_food'),
    expense(300, DateTime(2026, 10, 5), categoryId: 'cat_food'),
    expense(200, DateTime(2026, 10, 9), categoryId: 'cat_transport'),
    income(60000, DateTime(2026, 10, 1)),
    MoneyTransaction(
      id: 't1',
      type: TxnType.transfer,
      amount: 1000,
      date: DateTime(2026, 10, 3),
      fromAccountId: 'acc_cash',
      toAccountId: 'acc_ccp',
    ),
  ];

  group('buildMonthlyReport', () {
    test('sums income and expenses, excluding transfers', () {
      final report = buildMonthlyReport(
        transactions: october,
        categories: const [food, transport],
        monthKey: '2026-10',
      );

      expect(report.income, 60000);
      expect(report.expense, 1000);
      expect(report.net, 59000);
      expect(report.operationsCount, 5);
    });

    test('groups expenses by category, biggest first', () {
      final report = buildMonthlyReport(
        transactions: october,
        categories: const [food, transport],
        monthKey: '2026-10',
      );

      expect(report.byCategory, hasLength(2));
      expect(report.byCategory.first.categoryId, 'cat_food');
      expect(report.byCategory.first.total, 800);
      expect(report.byCategory.first.count, 2);
      expect(report.byCategory.first.name, 'طعام');
      expect(report.byCategory[1].categoryId, 'cat_transport');
      expect(report.byCategory[1].total, 200);
    });

    test('ignores operations of other months', () {
      final report = buildMonthlyReport(
        transactions: [
          ...october,
          expense(999, DateTime(2026, 9, 30), categoryId: 'cat_food'),
          income(1, DateTime(2026, 11, 1)),
        ],
        categories: const [food, transport],
        monthKey: '2026-10',
      );

      expect(report.income, 60000);
      expect(report.expense, 1000);
    });

    test('bucket uncategorized expenses under an empty id', () {
      final report = buildMonthlyReport(
        transactions: [expense(50, DateTime(2026, 10, 20))],
        categories: const [food, transport],
        monthKey: '2026-10',
      );

      expect(report.byCategory.single.categoryId, '');
      expect(report.byCategory.single.name, '');
      expect(report.byCategory.single.total, 50);
    });

    test('empty month reports isEmpty', () {
      final report = buildMonthlyReport(
        transactions: october,
        categories: const [food, transport],
        monthKey: '2026-08',
      );
      expect(report.isEmpty, isTrue);
    });
  });
}
