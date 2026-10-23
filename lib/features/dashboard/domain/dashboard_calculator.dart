import '../../../core/domain/pay_period.dart';
import '../../debts/models/debt.dart';
import '../../goals/models/goal.dart';
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
    required this.goalsSetAside,
    required this.dawraNet,
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

  /// Net amount moved into savings goals during the period (deposits minus
  /// withdrawals). That money left the wallets without being an expense, so
  /// it is no longer available to spend.
  final int goalsSetAside;

  /// Dawra pots received minus contributions/pots paid during the period.
  /// Kept out of income/expenses (it is savings, not consumption) but it is
  /// real cash, so it still counts in [remaining].
  final int dawraNet;

  /// salary + extra income - expenses - unpaid subscriptions - due debts
  /// - goals set aside + dawra net.
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

/// Deposits minus withdrawals of every goal whose entry falls in [period].
int goalsNetSetAside(List<Goal> goals, PayPeriod period) {
  var total = 0;
  for (final goal in goals) {
    for (final entry in goal.entries) {
      if (!period.contains(entry.date)) continue;
      total += entry.withdraw ? -entry.amount : entry.amount;
    }
  }
  return total;
}

DashboardData buildDashboard({
  required DateTime now,
  required UserSettings settings,
  required List<MoneyTransaction> periodTransactions,
  required List<MoneyTransaction> previousTransactions,
  required List<Debt> debts,
  int unpaidSubscriptionsDue = 0,
  List<Goal> goals = const [],
}) {
  final payday = settings.payday.clamp(1, 31);
  final period = PayPeriodCalculator.of(now: now, payday: payday);
  final previousPeriod = PayPeriodCalculator.previous(now: now, payday: payday);

  var income = 0;
  var salaryRecorded = 0;
  var expenses = 0;
  var dawraNet = 0;
  final byCategory = <String, int>{};

  for (final txn in periodTransactions) {
    if (txn.type == TxnType.transfer) continue;
    if (txn.source == TxnSource.dawra) {
      dawraNet += txn.isIncome ? txn.amount : -txn.amount;
      continue;
    }
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
    if (txn.source == TxnSource.dawra) continue;
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
  final goalsSetAside = goalsNetSetAside(goals, period);
  final remaining =
      settings.salary +
      extraIncome -
      expenses -
      unpaidSubscriptionsDue -
      debtsDue -
      goalsSetAside +
      dawraNet;

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
    goalsSetAside: goalsSetAside,
    dawraNet: dawraNet,
  );
}
