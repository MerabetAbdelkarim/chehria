import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/core/localization/s.dart';
import 'package:masarifi/core/notifications/notifications_service.dart';
import 'package:masarifi/features/debts/models/debt.dart';
import 'package:masarifi/features/notifications/domain/reminder_planner.dart';
import 'package:masarifi/features/subscriptions/domain/subscription_calculator.dart';
import 'package:masarifi/features/subscriptions/models/subscription.dart';

void main() {
  final s = S('ar');

  Subscription sub({String id = 's1', bool isActive = true, DateTime? due}) =>
      Subscription(
        id: id,
        name: 'كوفي',
        amount: 500,
        cycle: SubscriptionCycle.monthly,
        nextDueDate: due ?? DateTime(2026, 3, 10),
        isActive: isActive,
      );

  Debt debt({
    String id = 'd1',
    DateTime? due,
    List<DebtPayment> payments = const [],
  }) => Debt(
    id: id,
    type: DebtType.iOwe,
    person: 'محمد',
    amount: 2000,
    date: DateTime(2026, 1, 1),
    dueDate: due,
    payments: payments,
  );

  List<Reminder> build({
    DateTime? now,
    int payday = 1,
    List<Subscription> subscriptions = const [],
    List<Debt> debts = const [],
  }) => buildReminders(
    now: now ?? DateTime(2026, 3, 2, 10),
    s: s,
    payday: payday,
    subscriptions: subscriptions,
    debts: debts,
  );

  test('always reminds the evening before and on the pay day', () {
    final reminders = build(now: DateTime(2026, 3, 2, 10), payday: 1);

    final ids = reminders.map((r) => r.id).toList();
    expect(ids, contains(Reminder.stableId('payday')));
    expect(ids, contains(Reminder.stableId('payday:eve')));

    final dayOf = reminders.firstWhere(
      (r) => r.id == Reminder.stableId('payday'),
    );
    expect(dayOf.fireAt, DateTime(2026, 4, 1, reminderHour));
    expect(dayOf.body, s.paydayToday);

    final eve = reminders.firstWhere(
      (r) => r.id == Reminder.stableId('payday:eve'),
    );
    expect(eve.fireAt, DateTime(2026, 3, 31, paydayReminderHour));
    expect(eve.body, s.paydayTomorrow);
  });

  test('pay day is clamped to the last day of shorter months', () {
    final reminders = build(now: DateTime(2026, 1, 2, 10), payday: 31);
    final dayOf = reminders.firstWhere(
      (r) => r.id == Reminder.stableId('payday'),
    );
    expect(dayOf.fireAt, DateTime(2026, 1, 31, reminderHour));
  });

  test('an active subscription is reminded the day before and the day of', () {
    final reminders = build(subscriptions: [sub(due: DateTime(2026, 3, 10))]);

    final due = reminders.firstWhere(
      (r) => r.id == Reminder.stableId('sub:s1:due'),
    );
    final eve = reminders.firstWhere(
      (r) => r.id == Reminder.stableId('sub:s1:eve'),
    );

    expect(due.fireAt, DateTime(2026, 3, 10, reminderHour));
    expect(eve.fireAt, DateTime(2026, 3, 9, reminderHour));
    expect(due.title, 'كوفي');
    expect(due.body, contains('500'));
  });

  test('a paused subscription never reminds', () {
    final reminders = build(
      subscriptions: [sub(isActive: false, due: DateTime(2026, 3, 10))],
    );
    expect(
      reminders.where((r) => r.id == Reminder.stableId('sub:s1:due')),
      isEmpty,
    );
  });

  test('reminders in the past are dropped', () {
    // Subscription due today at 09:00 while "now" is already 10:00.
    final reminders = build(
      now: DateTime(2026, 3, 2, 10),
      subscriptions: [sub(due: DateTime(2026, 3, 2))],
    );
    expect(
      reminders.where((r) => r.id == Reminder.stableId('sub:s1:due')),
      isEmpty,
    );
    // …but the day-before reminder scheduled for tomorrow's due date survives
    // when the bill is due tomorrow.
    final tomorrow = build(
      now: DateTime(2026, 3, 2, 10),
      subscriptions: [sub(due: DateTime(2026, 3, 3))],
    );
    expect(
      tomorrow.where((r) => r.id == Reminder.stableId('sub:s1:due')),
      isNotEmpty,
    );
  });

  test('an unpaid debt with a due date reminds', () {
    final reminders = build(debts: [debt(due: DateTime(2026, 3, 20))]);
    final due = reminders.firstWhere(
      (r) => r.id == Reminder.stableId('debt:d1:due'),
    );
    expect(due.fireAt, DateTime(2026, 3, 20, reminderHour));
    expect(due.title, 'محمد');
  });

  test('a settled debt never reminds', () {
    final reminders = build(
      debts: [
        debt(
          due: DateTime(2026, 3, 20),
          payments: [DebtPayment(amount: 2000, date: DateTime(2026, 3, 1))],
        ),
      ],
    );
    expect(
      reminders.where((r) => r.id == Reminder.stableId('debt:d1:due')),
      isEmpty,
    );
  });

  test('a debt without due date never reminds', () {
    final reminders = build(debts: [debt(due: null)]);
    expect(reminders.where((r) => r.id.toString().contains('d1')), isEmpty);
  });

  test('Reminder.stableId is deterministic and non-negative', () {
    final a = Reminder.stableId('sub:s1:due');
    final b = Reminder.stableId('sub:s1:due');
    expect(a, b);
    expect(a, greaterThanOrEqualTo(0));
    expect(a, isNot(Reminder.stableId('sub:s2:due')));
  });
}
