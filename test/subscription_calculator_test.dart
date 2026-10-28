import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/features/subscriptions/domain/subscription_calculator.dart';

void main() {
  group('advanceDueDate', () {
    test('weekly adds seven days', () {
      final next = advanceDueDate(
        DateTime(2026, 3, 1),
        SubscriptionCycle.weekly,
      );
      expect(next, DateTime(2026, 3, 8));
    });

    test('monthly keeps the day of the month', () {
      final next = advanceDueDate(
        DateTime(2026, 3, 15),
        SubscriptionCycle.monthly,
      );
      expect(next, DateTime(2026, 4, 15));
    });

    test('monthly clamps 31 January to 28 February', () {
      final next = advanceDueDate(
        DateTime(2026, 1, 31),
        SubscriptionCycle.monthly,
      );
      expect(next, DateTime(2026, 2, 28));
    });

    test('monthly clamps 31 January to 29 February in a leap year', () {
      final next = advanceDueDate(
        DateTime(2024, 1, 31),
        SubscriptionCycle.monthly,
      );
      expect(next, DateTime(2024, 2, 29));
    });

    test('yearly clamps 29 February to 28 February', () {
      final next = advanceDueDate(
        DateTime(2024, 2, 29),
        SubscriptionCycle.yearly,
      );
      expect(next, DateTime(2025, 2, 28));
    });

    test('yearly keeps a regular day', () {
      final next = advanceDueDate(
        DateTime(2026, 6, 10),
        SubscriptionCycle.yearly,
      );
      expect(next, DateTime(2027, 6, 10));
    });
  });

  group('nextDueAfter', () {
    test('a due date in the past advances until it is not before [from]', () {
      final next = nextDueAfter(
        DateTime(2026, 1, 5),
        SubscriptionCycle.monthly,
        DateTime(2026, 3, 10),
      );
      expect(next, DateTime(2026, 4, 5));
    });

    test('a due date equal to [from] is kept', () {
      final next = nextDueAfter(
        DateTime(2026, 3, 10),
        SubscriptionCycle.monthly,
        DateTime(2026, 3, 10),
      );
      expect(next, DateTime(2026, 3, 10));
    });

    test('a due date in the future is kept', () {
      final next = nextDueAfter(
        DateTime(2026, 3, 20),
        SubscriptionCycle.monthly,
        DateTime(2026, 3, 10),
      );
      expect(next, DateTime(2026, 3, 20));
    });
  });

  group('due helpers', () {
    test('isDueBefore is exclusive', () {
      expect(isDueBefore(DateTime(2026, 3, 10), DateTime(2026, 3, 11)), isTrue);
      expect(
        isDueBefore(DateTime(2026, 3, 11), DateTime(2026, 3, 11)),
        isFalse,
      );
    });

    test('isOverdue only looks at the calendar day', () {
      expect(
        isOverdue(DateTime(2026, 3, 1, 23, 59), DateTime(2026, 3, 2, 0, 5)),
        isTrue,
      );
      expect(
        isOverdue(DateTime(2026, 3, 2, 0, 1), DateTime(2026, 3, 2, 23, 0)),
        isFalse,
      );
    });

    test('isDueToday and isDueTomorrow compare whole days', () {
      final now = DateTime(2026, 3, 2, 18);
      expect(isDueToday(DateTime(2026, 3, 2, 8), now), isTrue);
      expect(isDueTomorrow(DateTime(2026, 3, 3, 8), now), isTrue);
      expect(isDueTomorrow(DateTime(2026, 3, 4, 8), now), isFalse);
    });

    test('daysUntil counts calendar days', () {
      expect(daysUntil(DateTime(2026, 3, 7), DateTime(2026, 3, 2)), 5);
      expect(daysUntil(DateTime(2026, 3, 2), DateTime(2026, 3, 2)), 0);
      expect(daysUntil(DateTime(2026, 3, 1), DateTime(2026, 3, 2)), -1);
    });
  });
}
