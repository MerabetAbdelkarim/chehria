import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/core/domain/debt_calculator.dart';
import 'package:chehria/features/debts/models/debt.dart';

void main() {
  group('debtRemaining', () {
    test('is the amount minus every partial payment', () {
      expect(debtRemaining(10000, const [2000, 3000]), 5000);
      expect(debtRemaining(10000, const []), 10000);
      expect(debtRemaining(10000, const [10000]), 0);
    });

    test('handles multiple small payments', () {
      expect(debtRemaining(1000, const [100, 100, 100, 100, 100]), 500);
    });

    test('treats overpayment as settled', () {
      expect(debtRemaining(1000, const [1200]), -200);
      expect(isDebtSettled(debtRemaining(1000, const [1200])), isTrue);
    });

    test('is not settled while something remains', () {
      expect(isDebtSettled(debtRemaining(1000, const [999])), isFalse);
      expect(isDebtSettled(debtRemaining(1000, const [1000])), isTrue);
    });
  });

  group('debtPaidTotal', () {
    test('sums the payments', () {
      expect(debtPaidTotal(const [1, 2, 3]), 6);
      expect(debtPaidTotal(const []), 0);
    });
  });

  group('daysBetween', () {
    test('returns whole days ignoring the time of day', () {
      expect(daysBetween(DateTime(2026, 1, 1), DateTime(2026, 3, 1)), 59);
      expect(
        daysBetween(DateTime(2026, 1, 1, 23, 0), DateTime(2026, 1, 2, 1)),
        1,
      );
    });

    test('is never negative', () {
      expect(daysBetween(DateTime(2026, 5, 10), DateTime(2026, 5, 1)), 0);
    });
  });

  group('isOldDebt', () {
    final now = DateTime(2026, 10, 12);

    test('is true when open for more than 60 days and unpaid', () {
      expect(
        isOldDebt(date: DateTime(2026, 7, 1), now: now, remaining: 5000),
        isTrue,
      );
    });

    test('is false at exactly 60 days', () {
      // 12 Oct - 60 days = 13 Aug
      expect(
        isOldDebt(date: DateTime(2026, 8, 13), now: now, remaining: 5000),
        isFalse,
      );
    });

    test('is false when the debt is settled', () {
      expect(
        isOldDebt(date: DateTime(2026, 1, 1), now: now, remaining: 0),
        isFalse,
      );
    });

    test('honours a custom threshold', () {
      expect(
        isOldDebt(
          date: DateTime(2026, 10, 1),
          now: now,
          remaining: 100,
          thresholdDays: 5,
        ),
        isTrue,
      );
    });
  });

  group('isDebtDueBefore', () {
    final payday = DateTime(2026, 11, 1);

    test('counts a due date placed before the payday', () {
      expect(
        isDebtDueBefore(dueDate: DateTime(2026, 10, 20), dueBefore: payday),
        isTrue,
      );
    });

    test('does not count a due date on or after the payday', () {
      expect(
        isDebtDueBefore(dueDate: DateTime(2026, 11, 1), dueBefore: payday),
        isFalse,
      );
      expect(
        isDebtDueBefore(dueDate: DateTime(2026, 11, 10), dueBefore: payday),
        isFalse,
      );
    });

    test('does not count a debt without due date', () {
      expect(isDebtDueBefore(dueDate: null, dueBefore: payday), isFalse);
    });
  });

  group('Debt model', () {
    Debt build({
      List<DebtPayment> payments = const [],
      DebtType type = DebtType.iOwe,
    }) {
      return Debt(
        id: 'd1',
        type: type,
        person: 'محمد',
        amount: 20000,
        date: DateTime(2026, 1, 1),
        payments: payments,
      );
    }

    test('remaining and settled follow the partial payments', () {
      final debt = build(
        payments: [
          DebtPayment(amount: 5000, date: DateTime(2026, 2, 1)),
          DebtPayment(amount: 5000, date: DateTime(2026, 3, 1)),
        ],
      );

      expect(debt.paidTotal, 10000);
      expect(debt.remaining, 10000);
      expect(debt.isSettled, isFalse);
    });

    test('copyWith keeps the payments list', () {
      final debt = build();
      final updated = debt.copyWith(
        payments: [DebtPayment(amount: 20000, date: DateTime(2026, 4, 1))],
      );

      expect(updated.remaining, 0);
      expect(updated.isSettled, isTrue);
      expect(debt.remaining, 20000); // original untouched
    });

    test('detects old debts owed to me after 60 days', () {
      final debt = Debt(
        id: 'd2',
        type: DebtType.owedToMe,
        person: 'سمير',
        amount: 3000,
        date: DateTime(2026, 6, 1),
      );

      expect(debt.isOld(DateTime(2026, 10, 12)), isTrue);
      expect(debt.isOld(DateTime(2026, 7, 1)), isFalse);
    });
  });
}
