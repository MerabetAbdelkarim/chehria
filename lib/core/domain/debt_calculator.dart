/// Pure debt domain logic (used by both debt types: `iOwe` and `owedToMe`).
library;

/// Amount still owed after applying every partial payment.
///
/// A debt is settled when the remaining amount is `<= 0` (overpayment counts
/// as settled).
int debtRemaining(int totalAmount, Iterable<int> payments) {
  var paid = 0;
  for (final p in payments) {
    paid += p;
  }
  return totalAmount - paid;
}

/// Whether [remaining] means the debt is fully repaid.
bool isDebtSettled(int remaining) => remaining <= 0;

/// Total of all partial payments.
int debtPaidTotal(Iterable<int> payments) {
  var paid = 0;
  for (final p in payments) {
    paid += p;
  }
  return paid;
}

/// Whole days between [from] and [now] (date parts), never negative.
int daysBetween(DateTime from, DateTime now) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(now.year, now.month, now.day);
  final days = b.difference(a).inDays;
  return days < 0 ? 0 : days;
}

/// A debt is "old" when it has been open for more than [thresholdDays]
/// (60 days by default) and is not settled.
bool isOldDebt({
  required DateTime date,
  required DateTime now,
  required int remaining,
  int thresholdDays = 60,
}) => !isDebtSettled(remaining) && daysBetween(date, now) > thresholdDays;

/// A debt must be counted in the "due before pay day" bucket when it has an
/// explicit due date placed strictly before [dueBefore].
bool isDebtDueBefore({
  required DateTime? dueDate,
  required DateTime dueBefore,
}) {
  if (dueDate == null) return false;
  final d = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final b = DateTime(dueBefore.year, dueBefore.month, dueBefore.day);
  return d.isBefore(b);
}

/// Sum of the remaining parts of the given debts.
int totalRemaining(Iterable<int> remainingAmounts) {
  var total = 0;
  for (final r in remainingAmounts) {
    total += r;
  }
  return total;
}
