import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/core/domain/pay_period.dart';

void main() {
  group('PayPeriodCalculator.clampPayday', () {
    test('clamps 31 to February', () {
      expect(PayPeriodCalculator.clampPayday(31, 2026, 2), 28);
    });

    test('clamps 31 to February of a leap year', () {
      expect(PayPeriodCalculator.clampPayday(31, 2028, 2), 29);
    });

    test('clamps 31 to 30-day months', () {
      expect(PayPeriodCalculator.clampPayday(31, 2026, 4), 30);
      expect(PayPeriodCalculator.clampPayday(31, 2026, 6), 30);
      expect(PayPeriodCalculator.clampPayday(31, 2026, 11), 30);
    });

    test('keeps 31 in 31-day months', () {
      expect(PayPeriodCalculator.clampPayday(31, 2026, 1), 31);
      expect(PayPeriodCalculator.clampPayday(31, 2026, 8), 31);
    });

    test('normalizes out-of-range values', () {
      expect(PayPeriodCalculator.clampPayday(0, 2026, 5), 1);
      expect(PayPeriodCalculator.clampPayday(99, 2026, 5), 31);
    });
  });

  group('PayPeriodCalculator.of', () {
    test('mid-month period runs from the 1st to the next 1st', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 10, 12),
        payday: 1,
      );
      expect(period.start, DateTime(2026, 10, 1));
      expect(period.end, DateTime(2026, 11, 1));
      expect(period.totalDays, 31);
    });

    test('a new period starts exactly on the pay day', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 11, 1),
        payday: 1,
      );
      expect(period.start, DateTime(2026, 11, 1));
      expect(period.end, DateTime(2026, 12, 1));
    });

    test('the day before the pay day still belongs to the old period', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 10, 31),
        payday: 1,
      );
      expect(period.start, DateTime(2026, 10, 1));
      expect(period.end, DateTime(2026, 11, 1));
      expect(period.daysLeft(DateTime(2026, 10, 31)), 1);
    });

    test('pay day 15 splits the month in the middle', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 10, 20),
        payday: 15,
      );
      expect(period.start, DateTime(2026, 10, 15));
      expect(period.end, DateTime(2026, 11, 15));
      expect(period.daysLeft(DateTime(2026, 10, 20)), 26);
    });

    test('pay day 31 ends on the last day of a shorter month', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 2, 20),
        payday: 31,
      );
      expect(period.start, DateTime(2026, 1, 31));
      expect(period.end, DateTime(2026, 2, 28));
      expect(period.daysLeft(DateTime(2026, 2, 20)), 8);
    });

    test('pay day 31 in April ends on the 30th', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 4, 15),
        payday: 31,
      );
      expect(period.start, DateTime(2026, 3, 31));
      expect(period.end, DateTime(2026, 4, 30));
    });

    test('crosses the year boundary in December', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 12, 15),
        payday: 1,
      );
      expect(period.start, DateTime(2026, 12, 1));
      expect(period.end, DateTime(2027, 1, 1));
    });

    test('pay day 31 in January starts from the previous 31', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 1, 10),
        payday: 31,
      );
      expect(period.start, DateTime(2025, 12, 31));
      expect(period.end, DateTime(2026, 1, 31));
    });
  });

  group('PayPeriod.daysLeft', () {
    test('counts whole days until the pay day, ignoring the time of day', () {
      final period = PayPeriodCalculator.of(
        now: DateTime(2026, 10, 26, 23, 59),
        payday: 1,
      );
      expect(period.daysLeft(DateTime(2026, 10, 26, 0, 1)), 6);
      expect(period.daysLeft(DateTime(2026, 10, 26, 23, 59)), 6);
    });

    test('never returns a negative number', () {
      final period = PayPeriod(
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 11, 1),
      );
      expect(period.daysLeft(DateTime(2026, 12, 1)), 0);
    });
  });

  group('PayPeriod.contains', () {
    final period = PayPeriod(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 11, 1),
    );

    test('includes the first day and excludes the end day', () {
      expect(period.contains(DateTime(2026, 10, 1)), isTrue);
      expect(period.contains(DateTime(2026, 10, 31, 23, 30)), isTrue);
      expect(period.contains(DateTime(2026, 11, 1)), isFalse);
      expect(period.contains(DateTime(2026, 9, 30)), isFalse);
    });
  });

  group('PayPeriodCalculator.previous', () {
    test('the previous period ends where the current one starts', () {
      final now = DateTime(2026, 10, 12);
      final current = PayPeriodCalculator.of(now: now, payday: 1);
      final previous = PayPeriodCalculator.previous(now: now, payday: 1);

      expect(previous.start, DateTime(2026, 9, 1));
      expect(previous.end, current.start);
      expect(previous.totalDays, 30);
    });
  });
}
