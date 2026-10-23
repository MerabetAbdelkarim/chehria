import '../../../core/domain/pay_period.dart';
import '../../../core/localization/s.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../core/utils/formatters.dart';
import '../../debts/models/debt.dart';
import '../../subscriptions/models/subscription.dart';

/// When the reminder rings.
const int reminderHour = 9;

/// The pay-day reminder rings in the evening of the previous day.
const int paydayReminderHour = 19;

/// Decides which local reminders exist for the current data set.
///
/// Pure function — unit tested. Times are plain local wall-clock [DateTime]s;
/// the service converts them to the device zone.
List<Reminder> buildReminders({
  required DateTime now,
  required S s,
  required int payday,
  required List<Subscription> subscriptions,
  required List<Debt> debts,
}) {
  final out = <Reminder>[];

  // ------------------------------------------------------------ pay day
  final period = PayPeriodCalculator.of(now: now, payday: payday.clamp(1, 31));
  final payDay = DateTime(period.end.year, period.end.month, period.end.day);
  out.add(
    Reminder(
      id: Reminder.stableId('payday'),
      title: s.appName,
      body: s.paydayToday,
      fireAt: DateTime(payDay.year, payDay.month, payDay.day, reminderHour),
    ),
  );
  out.add(
    Reminder(
      id: Reminder.stableId('payday:eve'),
      title: s.appName,
      body: s.paydayTomorrow,
      fireAt: DateTime(
        payDay.year,
        payDay.month,
        payDay.day - 1,
        paydayReminderHour,
      ),
    ),
  );

  // -------------------------------------------------------- subscriptions
  for (final sub in subscriptions) {
    if (!sub.isActive) continue;
    final due = sub.nextDueDate;
    final label = formatDzd(sub.amount);
    out.add(
      Reminder(
        id: Reminder.stableId('sub:${sub.id}:due'),
        title: sub.name,
        body: '${s.subscriptionDueToday} — $label',
        fireAt: DateTime(due.year, due.month, due.day, reminderHour),
      ),
    );
    out.add(
      Reminder(
        id: Reminder.stableId('sub:${sub.id}:eve'),
        title: sub.name,
        body: '${s.subscriptionDueTomorrow} — $label',
        fireAt: DateTime(due.year, due.month, due.day - 1, reminderHour),
      ),
    );
  }

  // -------------------------------------------------------------- debts
  for (final debt in debts) {
    final due = debt.dueDate;
    if (due == null || debt.isSettled) continue;
    final label = formatDzd(debt.remaining);
    out.add(
      Reminder(
        id: Reminder.stableId('debt:${debt.id}:due'),
        title: debt.person,
        body: '${s.debtDueToday} — $label',
        fireAt: DateTime(due.year, due.month, due.day, reminderHour),
      ),
    );
    out.add(
      Reminder(
        id: Reminder.stableId('debt:${debt.id}:eve'),
        title: debt.person,
        body: '${s.debtDueToday} — $label',
        fireAt: DateTime(due.year, due.month, due.day - 1, reminderHour),
      ),
    );
  }

  out.removeWhere((r) => !r.fireAt.isAfter(now));
  return out;
}
