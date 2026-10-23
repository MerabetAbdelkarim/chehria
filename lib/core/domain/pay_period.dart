/// Pure pay-period domain logic.
///
/// The pay period starts on the user's pay day and ends the day before the
/// next pay day. The pay day is a day of month (1-31) clamped to the last day
/// of shorter months (e.g. 31 -> 28/29 in February).
library;

/// An interval `[start, end)` where `start` is a pay day and `end` is the next
/// pay day (both at 00:00, `end` exclusive).
class PayPeriod {
  const PayPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// Number of days covered by this period.
  int get totalDays => end.difference(start).inDays;

  /// Whole days remaining from [now] (date part) until the next pay day.
  /// The day of the pay day itself is not counted: money must last until the
  /// salary arrives. Never returns less than `0`.
  int daysLeft(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final left = end.difference(today).inDays;
    return left < 0 ? 0 : left;
  }

  /// Whether the date part of [date] falls inside this period.
  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && d.isBefore(end);
  }

  @override
  String toString() => 'PayPeriod($start -> $end)';
}

/// Calculates pay periods from a pay day of month.
class PayPeriodCalculator {
  PayPeriodCalculator._();

  /// Last day of `[year, month]` (month is 1-12).
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// [payday] clamped to the real length of `[year, month]`.
  static int clampPayday(int payday, int year, int month) {
    final normalized = payday < 1 ? 1 : (payday > 31 ? 31 : payday);
    final max = daysInMonth(year, month);
    return normalized > max ? max : normalized;
  }

  /// The pay day date inside `[year, month]` (month may overflow, e.g. 13).
  static DateTime paydayIn(int year, int month, int payday) =>
      DateTime(year, month, clampPayday(payday, year, month));

  /// The period containing [now].
  ///
  /// - If today is on/after this month's pay day, the period started this
  ///   month (a new period starts exactly on pay day).
  /// - Otherwise the period started last month.
  static PayPeriod of({required DateTime now, required int payday}) {
    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = paydayIn(now.year, now.month, payday);

    final DateTime start;
    if (!today.isBefore(thisMonth)) {
      start = thisMonth;
    } else {
      start = paydayIn(now.year, now.month - 1, payday);
    }

    final DateTime end = thisMonth.isAfter(today)
        ? thisMonth
        : paydayIn(now.year, now.month + 1, payday);

    return PayPeriod(start: start, end: end);
  }

  /// The period that immediately precedes the period containing [now].
  static PayPeriod previous({required DateTime now, required int payday}) {
    final current = of(now: now, payday: payday);
    final start = paydayIn(current.start.year, current.start.month - 1, payday);
    return PayPeriod(start: start, end: current.start);
  }
}
