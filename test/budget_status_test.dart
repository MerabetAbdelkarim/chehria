import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/features/budgets/domain/budget_status.dart';
import 'package:masarifi/features/budgets/models/budget.dart';

void main() {
  group('budgetLevel', () {
    test('is ok below 80 % of the limit', () {
      expect(budgetLevel(limit: 1000, spent: 799), BudgetLevel.ok);
    });

    test('is warning at exactly 80 %', () {
      expect(budgetLevel(limit: 1000, spent: 800), BudgetLevel.warning);
    });

    test('is warning between 80 % and the limit', () {
      expect(budgetLevel(limit: 1000, spent: 950), BudgetLevel.warning);
    });

    test('is exceeded at the limit', () {
      expect(budgetLevel(limit: 1000, spent: 1000), BudgetLevel.exceeded);
    });

    test('is exceeded above the limit', () {
      expect(budgetLevel(limit: 1000, spent: 1200), BudgetLevel.exceeded);
    });

    test('a non-positive limit never alerts', () {
      expect(budgetLevel(limit: 0, spent: 500), BudgetLevel.ok);
    });
  });

  group('budgetRemaining', () {
    test('subtracts spent from the limit', () {
      expect(budgetRemaining(limit: 1000, spent: 400), 600);
    });

    test('never goes negative', () {
      expect(budgetRemaining(limit: 1000, spent: 1500), 0);
    });

    test('is zero for a zero limit', () {
      expect(budgetRemaining(limit: 0, spent: 100), 0);
    });
  });

  group('budgetRatio', () {
    test('is spent over limit', () {
      expect(budgetRatio(limit: 200, spent: 50), 0.25);
    });

    test('is 0 for a zero limit', () {
      expect(budgetRatio(limit: 0, spent: 10), 0);
    });
  });

  group('Budget month keys', () {
    test('monthKeyOf pads single-digit months', () {
      expect(Budget.monthKeyOf(DateTime(2026, 1, 15)), '2026-01');
      expect(Budget.monthKeyOf(DateTime(2026, 10, 1)), '2026-10');
    });

    test('monthStart / monthEnd bracket the whole month', () {
      final start = Budget.monthStart('2026-02');
      final end = Budget.monthEnd('2026-02');
      expect(start, DateTime(2026, 2));
      expect(end, DateTime(2026, 3));
      expect(end.difference(start).inDays, 28);
    });

    test('addMonths rolls over year boundaries', () {
      expect(Budget.addMonths('2026-12', 1), '2027-01');
      expect(Budget.addMonths('2026-01', -1), '2025-12');
      expect(Budget.addMonths('2026-06', -6), '2025-12');
    });
  });
}
