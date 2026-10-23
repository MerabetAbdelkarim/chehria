/// Pure logic for recurring bills (subscription cycles, due dates).
///
/// Nothing here touches Flutter or Firebase, so it is fully unit-testable.
enum SubscriptionCycle {
  weekly,
  monthly,
  yearly;

  static SubscriptionCycle fromId(String? id) => SubscriptionCycle.values
      .firstWhere((c) => c.name == id, orElse: () => SubscriptionCycle.monthly);
}

/// One occurrence after [date] for the given cycle.
///
/// Monthly/yearly dates are clamped to the last day of shorter months, the
/// same way the pay day is (`31 January + 1 month = 28/29 February`).
DateTime advanceDueDate(DateTime date, SubscriptionCycle cycle) {
  switch (cycle) {
    case SubscriptionCycle.weekly:
      return date.add(const Duration(days: 7));
    case SubscriptionCycle.monthly:
      return _addMonths(date, 1);
    case SubscriptionCycle.yearly:
      return _addMonths(date, 12);
  }
}

/// The first occurrence of the cycle that is **not before** [from].
///
/// Used after a payment: a bill paid today never comes due again today.
DateTime nextDueAfter(DateTime due, SubscriptionCycle cycle, DateTime from) {
  var next = due;
  var guard = 0;
  while (next.isBefore(from) && guard < 500) {
    next = advanceDueDate(next, cycle);
    guard++;
  }
  return next;
}

/// Next due date once the occurrence due on [due] has been paid at [paidAt].
///
/// A payment always settles the current occurrence, so the date moves at
/// least one cycle even when the bill is paid early; when it was overdue by
/// several cycles it lands on the first occurrence not before [paidAt].
DateTime dueAfterPayment(
  DateTime due,
  SubscriptionCycle cycle,
  DateTime paidAt,
) => nextDueAfter(advanceDueDate(due, cycle), cycle, paidAt);

/// Whether the bill falls due strictly before [limit] (exclusive, the pay
/// period end is exclusive too).
bool isDueBefore(DateTime due, DateTime limit) => due.isBefore(limit);

/// Day-level comparison, ignoring the time of day.
DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// `true` when [due] is a past calendar day (still unpaid).
bool isOverdue(DateTime due, DateTime now) => _dayOf(due).isBefore(_dayOf(now));

/// `true` when [due] is today.
bool isDueToday(DateTime due, DateTime now) => _dayOf(due) == _dayOf(now);

/// `true` when [due] is tomorrow.
bool isDueTomorrow(DateTime due, DateTime now) =>
    _dayOf(due).difference(_dayOf(now)).inDays == 1;

/// How many days until [due]; `0` for today, negative when overdue.
int daysUntil(DateTime due, DateTime now) =>
    _dayOf(due).difference(_dayOf(now)).inDays;

DateTime _addMonths(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) + months;
  final year = total ~/ 12;
  final month = (total % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(year, month, day, date.hour, date.minute, date.second);
}
