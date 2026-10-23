import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/features/goals/models/goal.dart';
import 'package:masarifi/features/dashboard/domain/dashboard_calculator.dart';
import 'package:masarifi/features/debts/models/debt.dart';
import 'package:masarifi/features/settings/models/user_settings.dart';
import 'package:masarifi/features/transactions/models/money_transaction.dart';

MoneyTransaction expense({
  required int amount,
  String category = 'cat_food',
  String account = 'acc_cash',
  TxnSource source = TxnSource.manual,
  DateTime? date,
}) {
  return MoneyTransaction(
    id: 't${amount}x${date?.millisecondsSinceEpoch ?? 0}',
    type: TxnType.expense,
    amount: amount,
    date: date ?? DateTime(2026, 10, 5),
    categoryId: category,
    accountId: account,
    source: source,
  );
}

MoneyTransaction income({
  required int amount,
  String category = 'cat_other',
  TxnSource source = TxnSource.manual,
  DateTime? date,
}) {
  return MoneyTransaction(
    id: 'i$amount',
    type: TxnType.income,
    amount: amount,
    date: date ?? DateTime(2026, 10, 5),
    categoryId: category,
    accountId: 'acc_cash',
    source: source,
  );
}

void main() {
  const settings = UserSettings(
    uid: 'u1',
    salary: 50000,
    payday: 1,
    setupCompleted: true,
  );
  final now = DateTime(2026, 10, 12, 10);

  group('daily allowance', () {
    test('is remaining divided by the days left until payday', () {
      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: const [],
        previousTransactions: const [],
        debts: const [],
      );

      expect(data.daysLeft, 20); // 12 Oct -> 1 Nov
      expect(data.remaining, 50000);
      expect(data.dailyAllowance, 2500);
      expect(data.isNegative, isFalse);
    });

    test('goes down when the period has expenses', () {
      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: [expense(amount: 10000)],
        previousTransactions: const [],
        debts: const [],
      );

      expect(data.remaining, 40000);
      expect(data.dailyAllowance, 2000);
    });

    test('adds extra income but never the recorded salary twice', () {
      final withExtraIncome = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: [income(amount: 5000)],
        previousTransactions: const [],
        debts: const [],
      );
      expect(withExtraIncome.extraIncome, 5000);
      expect(withExtraIncome.remaining, 55000);

      final withSalary = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: [
          income(
            amount: 50000,
            category: 'cat_salary',
            source: TxnSource.salary,
          ),
        ],
        previousTransactions: const [],
        debts: const [],
      );
      expect(withSalary.income, 50000);
      expect(withSalary.extraIncome, 0);
      expect(withSalary.remaining, 50000);
      expect(withSalary.salaryRecorded, isTrue);
    });

    test('turns negative with a warning when expenses exceed the budget', () {
      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: [expense(amount: 60000)],
        previousTransactions: const [],
        debts: const [],
      );

      expect(data.remaining, -10000);
      expect(data.isNegative, isTrue);
      expect(data.dailyAllowance, -500);
    });

    test('subtracts the debts I owe that fall due before payday', () {
      final dueSoon = Debt(
        id: 'd1',
        type: DebtType.iOwe,
        person: 'أمين',
        amount: 8000,
        date: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 20),
      );

      final dueAfterPayday = Debt(
        id: 'd2',
        type: DebtType.iOwe,
        person: 'كريم',
        amount: 3000,
        date: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 11, 5),
      );

      final noDueDate = Debt(
        id: 'd3',
        type: DebtType.iOwe,
        person: 'سمير',
        amount: 4000,
        date: DateTime(2026, 10, 1),
      );

      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: const [],
        previousTransactions: const [],
        debts: [dueSoon, dueAfterPayday, noDueDate],
      );

      expect(data.debtsDue, 8000);
      expect(data.totalIOwe, 15000);
      expect(data.remaining, 42000);
    });

    test('reports both sides of the net debts', () {
      final owedToMe = Debt(
        id: 'd4',
        type: DebtType.owedToMe,
        person: 'ياسين',
        amount: 10000,
        date: DateTime(2026, 9, 1),
        payments: const [],
      );
      final iOwe = Debt(
        id: 'd5',
        type: DebtType.iOwe,
        person: 'علي',
        amount: 4000,
        date: DateTime(2026, 9, 1),
        payments: const [],
      );

      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: const [],
        previousTransactions: const [],
        debts: [owedToMe, iOwe],
      );

      expect(data.totalOwedToMe, 10000);
      expect(data.totalIOwe, 4000);
      expect(data.netDebts, 6000);
    });
  });

  group('period aggregation', () {
    test('groups expenses by category and ignores transfers', () {
      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: [
          expense(amount: 1000, category: 'cat_food'),
          expense(amount: 500, category: 'cat_food'),
          expense(amount: 2000, category: 'cat_transport'),
          MoneyTransaction(
            id: 'tr1',
            type: TxnType.transfer,
            amount: 9999,
            date: DateTime(2026, 10, 5),
            fromAccountId: 'acc_cash',
            toAccountId: 'acc_ccp',
          ),
        ],
        previousTransactions: const [],
        debts: const [],
      );

      expect(data.expenses, 3500);
      expect(data.expensesByCategory['cat_food'], 1500);
      expect(data.expensesByCategory['cat_transport'], 2000);
    });

    test('excludes operations recorded outside the current period', () {
      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: const [],
        previousTransactions: [
          expense(amount: 7000, date: DateTime(2026, 9, 20)),
          income(amount: 50000, date: DateTime(2026, 9, 1)),
        ],
        debts: const [],
      );

      expect(data.previousExpenses, 7000);
      expect(data.previousIncome, 50000);
      expect(data.expenses, 0);
      expect(data.period.start, DateTime(2026, 10, 1));
      expect(data.previousPeriod.start, DateTime(2026, 9, 1));
    });
  });

  group('goals and dawra', () {
    test('money put into a goal this period is no longer spendable', () {
      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: const [],
        previousTransactions: const [],
        debts: const [],
        goals: [
          Goal(
            id: 'g1',
            name: 'Hajj',
            targetAmount: 100000,
            savedAmount: 12000,
            entries: [
              GoalEntry(amount: 10000, date: DateTime(2026, 10, 3)),
              GoalEntry(amount: 3000, date: DateTime(2026, 10, 8)),
              GoalEntry(
                amount: 1000,
                date: DateTime(2026, 10, 9),
                withdraw: true,
              ),
              // Previous period: already accounted for back then.
              GoalEntry(amount: 5000, date: DateTime(2026, 9, 20)),
            ],
          ),
        ],
      );

      expect(data.goalsSetAside, 12000);
      expect(data.remaining, 38000);
    });

    test('dawra flows stay out of income and expenses but count in cash', () {
      final data = buildDashboard(
        now: now,
        settings: settings,
        periodTransactions: [
          expense(amount: 5000, category: 'cat_dawra', source: TxnSource.dawra),
          income(amount: 15000, category: 'cat_dawra', source: TxnSource.dawra),
          expense(amount: 2000),
        ],
        previousTransactions: [
          expense(amount: 5000, category: 'cat_dawra', source: TxnSource.dawra),
        ],
        debts: const [],
      );

      expect(data.expenses, 2000);
      expect(data.extraIncome, 0);
      expect(data.expensesByCategory.containsKey('cat_dawra'), isFalse);
      expect(data.dawraNet, 10000);
      expect(data.remaining, 50000 - 2000 + 10000);
      expect(data.previousExpenses, 0);
    });
  });
}
