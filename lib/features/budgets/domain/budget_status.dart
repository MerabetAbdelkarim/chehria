import '../../../core/constants/app_constants.dart';

/// How full a budget is this month.
enum BudgetLevel {
  /// Below the warning threshold.
  ok,

  /// At least 80 % of the limit.
  warning,

  /// At or above the limit.
  exceeded,
}

/// Classifies `spent` against `limit` using [AppConstants.budgetAlert80].
BudgetLevel budgetLevel({required int limit, required int spent}) {
  if (limit <= 0) return BudgetLevel.ok;
  if (spent >= limit) return BudgetLevel.exceeded;
  if (spent >= limit * AppConstants.budgetAlert80) return BudgetLevel.warning;
  return BudgetLevel.ok;
}

/// Dinars left under the ceiling; never negative.
int budgetRemaining({required int limit, required int spent}) {
  if (limit <= 0) return 0;
  final rest = limit - spent;
  return rest < 0 ? 0 : rest;
}

/// `0.0`–`1.0+` ratio of the ceiling consumed (clamped for progress bars).
double budgetRatio({required int limit, required int spent}) {
  if (limit <= 0) return 0;
  return spent / limit;
}
