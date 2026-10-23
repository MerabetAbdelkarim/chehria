import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/features/seasonal/domain/algerian_events.dart';

void main() {
  group('upcomingEvents', () {
    test('includes known Ramadan and fixed annual events', () {
      final events = upcomingEvents(DateTime(2026, 1, 1));
      final ids = [for (final e in events) e.id];

      expect(ids, contains('ramadan_2026'));
      expect(ids, contains('eid_2026'));
      expect(ids, contains('school_2027'));
      expect(ids, contains('summer_2026'));
      expect(ids, contains('november_2026'));
      expect(ids, contains('newyear_2027'));
    });

    test('sorts soonest first and drops past events', () {
      final events = upcomingEvents(DateTime(2026, 10, 13));
      for (var i = 1; i < events.length; i++) {
        expect(
          events[i].date.isAfter(events[i - 1].date),
          isTrue,
          reason: 'events must be sorted by date',
        );
      }
      for (final e in events) {
        expect(e.date.isBefore(DateTime(2026, 10, 13)), isFalse);
      }
    });

    test('Ramadan 2026 starts 18 February 2026', () {
      final events = upcomingEvents(DateTime(2026, 1, 1));
      final ramadan = events.firstWhere((e) => e.id == 'ramadan_2026');
      expect(ramadan.date, DateTime(2026, 2, 18));
    });
  });

  group('monthsLeft', () {
    test('is at least 1', () {
      expect(monthsLeft(DateTime(2026, 10, 13), DateTime(2026, 10, 20)), 1);
    });

    test('counts full months into the future', () {
      expect(monthsLeft(DateTime(2026, 10, 13), DateTime(2027, 1, 18)), 3);
    });

    test('subtracts a partial month when the day has not arrived', () {
      // 13 Nov -> 12 Dec is not a full month yet.
      expect(monthsLeft(DateTime(2026, 10, 13), DateTime(2026, 12, 12)), 1);
      expect(monthsLeft(DateTime(2026, 10, 13), DateTime(2026, 12, 13)), 2);
    });
  });

  group('monthlySetAside', () {
    test('divides the remaining amount by months left', () {
      // 9,000 needed over 3 months.
      expect(
        monthlySetAside(
          target: 9000,
          saved: 0,
          now: DateTime(2026, 10, 13),
          date: DateTime(2027, 1, 18),
        ),
        3000,
      );
    });

    test('rounds up so the target is always reached', () {
      // 10,000 over 3 months -> 3,334 each month.
      expect(
        monthlySetAside(
          target: 10000,
          saved: 0,
          now: DateTime(2026, 10, 13),
          date: DateTime(2027, 1, 18),
        ),
        3334,
      );
    });

    test('is zero once the target is reached', () {
      expect(
        monthlySetAside(
          target: 5000,
          saved: 5000,
          now: DateTime(2026, 10, 13),
          date: DateTime(2026, 12, 1),
        ),
        0,
      );
    });

    test('accounts for already saved money', () {
      expect(
        monthlySetAside(
          target: 9000,
          saved: 3000,
          now: DateTime(2026, 10, 13),
          date: DateTime(2027, 1, 18),
        ),
        2000,
      );
    });
  });

  group('daysLeft', () {
    test('is zero for today', () {
      expect(daysLeft(DateTime(2026, 10, 13), DateTime(2026, 10, 13)), 0);
    });

    test('counts whole days until the date', () {
      expect(daysLeft(DateTime(2026, 10, 13), DateTime(2026, 10, 20)), 7);
    });

    test('is never negative for past dates', () {
      expect(daysLeft(DateTime(2026, 10, 13), DateTime(2026, 10, 1)), 0);
    });
  });
}
