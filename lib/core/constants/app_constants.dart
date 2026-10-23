/// Global constants of the app.
class AppConstants {
  AppConstants._();

  /// Currency symbol used for the Algerian Dinar.
  static const String currencySymbol = 'دج';

  /// Pay day of the month. `31` is clamped to the last day of shorter months.
  static const int minPayday = 1;
  static const int maxPayday = 31;

  /// Upper bound for a single amount (in dinars) to avoid nonsense input.
  static const int maxAmount = 99999999999;

  /// Debts owed to the user and unpaid for more than these days are highlighted.
  static const int oldDebtDays = 60;

  /// Budget alerts fire at these ratios of the monthly limit.
  static const double budgetAlert80 = 0.8;
  static const double budgetAlert100 = 1.0;

  /// How many past periods the dashboard compares with.
  static const int comparisonMonths = 6;

  /// Local storage keys.
  static const String keyCachedUid = 'cached_uid';

  /// Collection names under `users/{uid}/`.
  static const String colAccounts = 'accounts';
  static const String colCategories = 'categories';
  static const String colTransactions = 'transactions';
  static const String colSubscriptions = 'subscriptions';
  static const String colDebts = 'debts';
  static const String colBudgets = 'budgets';
  static const String colGoals = 'goals';
  static const String colDart = 'dart';
}
