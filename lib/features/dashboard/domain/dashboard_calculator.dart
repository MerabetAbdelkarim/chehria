import '../../../core/domain/pay_period.dart';
import '../../debts/models/debt.dart';
import '../../settings/models/user_settings.dart';
import '../../transactions/models/money_transaction.dart';

/// Everything the dashboard shows, computed from plain data (unit-testable).
class DashboardData {
  const DashboardData({
    required this.period,
    required this.previousPeriod,
    required this.salary,
    required this.income,
    required this.extraIncome,
    required this.expenses,
    required this.subscriptionsDue,
    required this.debtsDue,
    required this.remaining,
    required this.daysLeft,
    required this.dailyAllowance,
    required this.expensesByCategory,
    required this.previousIncome,
    required this.previousExpenses,
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.salaryRecordedAmount,
    required this.now,
  });

  final PayPeriod period;
  final PayPeriod previousPeriod;
  final DateTime now;

  /// Salary taken from settings (never a transaction).
  final int salary;

  /// Sum of every income operation of the period (salary included when it has
  /// been recorded).
  final int income;

  /// Income that is *not* the salary.
  final int extraIncome;

  final int expenses;

  /// Unpaid subscriptions falling due before the next pay day.
  final int subscriptionsDue;

  /// Remaining parts of the debts I owe that fall due before the next pay day.
  final int debtsDue;

  /// salary + extra income - expenses - unpaid subscriptions - due debts.
  final int remaining;

  final int daysLeft;

  /// `remaining / daysLeft` — negative when the budget is already exceeded.
  final double dailyAllowance;

  /// `categoryId -> expenses` of the current period.
  final Map<String, int> expensesByCategory;

  final int previousIncome;
  final int previousExpenses;

  final int totalOwedToMe;
  final int totalIOwe;

  /// Amount of the salary already recorded as a transaction this period.
  final int salaryRecordedAmount;

  bool get isNegative => remaining < 0;
  bool get salaryRecorded => salaryRecordedAmount > 0;

  int get netDebts => totalOwedToMe - totalIOwe;
}

DashboardData buildDashboard({
  required DateTime now,
  required UserSettings settings,
  required List<MoneyTransaction> periodTransactions,
  required List<MoneyTransaction> previousTransactions,
  required List<Debt> debts,
  int unpaidSubscriptionsDue = 0,
}) {
  final payday = settings.payday.clamp(1, 31);
  final period = PayPeriodCalculator.of(now: now, payday: payday);
  final previousPeriod = PayPeriodCalculator.previous(now: now, payday: payday);

  var income = 0;
  var salaryRecorded = 0;
  var expenses = 0;
  final byCategory = <String, int>{};

  for (final txn in periodTransactions) {
    if (txn.type == TxnType.transfer) continue;
    if (txn.type == TxnType.income) {
      income += txn.amount;
      if (txn.source == TxnSource.salary) salaryRecorded += txn.amount;
    } else {
      expenses += txn.amount;
      final key = txn.categoryId ?? '';
      byCategory[key] = (byCategory[key] ?? 0) + txn.amount;
    }
  }

  var previousIncome = 0;
  var previousExpenses = 0;
  for (final txn in previousTransactions) {
    if (txn.type == TxnType.income) {
      previousIncome += txn.amount;
    } else if (txn.type == TxnType.expense) {
      previousExpenses += txn.amount;
    }
  }

  var owedToMe = 0;
  var iOwe = 0;
  var debtsDue = 0;
  for (final debt in debts) {
    if (debt.type == DebtType.owedToMe) {
      owedToMe += debt.remaining;
    } else {
      iOwe += debt.remaining;
      if (debt.isDueBefore(period.end)) debtsDue += debt.remaining;
    }
  }

  final extraIncome = income - salaryRecorded;
  final remaining =
      settings.salary +
      extraIncome -
      expenses -
      unpaidSubscriptionsDue -
      debtsDue;

  final daysLeft = period.daysLeft(now);
  final dailyAllowance = daysLeft > 0 ? remaining / daysLeft : 0.0;

  return DashboardData(
    period: period,
    previousPeriod: previousPeriod,
    now: now,
    salary: settings.salary,
    income: income,
    extraIncome: extraIncome,
    expenses: expenses,
    subscriptionsDue: unpaidSubscriptionsDue,
    debtsDue: debtsDue,
    remaining: remaining,
    daysLeft: daysLeft,
    dailyAllowance: dailyAllowance,
    expensesByCategory: byCategory,
    previousIncome: previousIncome,
    previousExpenses: previousExpenses,
    totalOwedToMe: owedToMe,
    totalIOwe: iOwe,
    salaryRecordedAmount: salaryRecorded,
  );
}
