import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/core/utils/formatters.dart';

void main() {
  group('groupNumber', () {
    test('groups thousands with commas', () {
      expect(groupNumber(0), '0');
      expect(groupNumber(999), '999');
      expect(groupNumber(1000), '1,000');
      expect(groupNumber(1234567), '1,234,567');
      expect(groupNumber(-45000), '-45,000');
    });
  });

  group('formatDzd', () {
    test('appends the Algerian dinar symbol', () {
      expect(formatDzd(12500), '12,500 دج');
      expect(formatDzd(-800), '-800 دج');
    });
  });

  group('formatDzdAlgerian', () {
    test('10,000 DA is 1 million (centimes)', () {
      expect(formatDzdAlgerian(10000), '1 مليون');
    });

    test('scales bigger amounts in millions of centimes', () {
      expect(formatDzdAlgerian(25000), '2.5 مليون');
      expect(formatDzdAlgerian(1000000), '100 مليون');
    });

    test('uses thousands below one million centimes', () {
      expect(formatDzdAlgerian(1000), '100 ألف');
      expect(formatDzdAlgerian(100), '10 ألف');
    });

    test('falls back to dinars for very small amounts', () {
      expect(formatDzdAlgerian(5), '5 دج');
      expect(formatDzdAlgerian(0), '0 دج');
    });

    test('keeps the sign of negative amounts', () {
      expect(formatDzdAlgerian(-10000), '-1 مليون');
    });
  });

  group('formatAmount', () {
    test('switches between the two display modes', () {
      expect(formatAmount(45000, millionsMode: false), '45,000 دج');
      expect(formatAmount(45000, millionsMode: true), '4.5 مليون');
    });
  });

  group('formatDateShort', () {
    test('uses the numeric dd/mm/yyyy form', () {
      expect(formatDateShort(DateTime(2026, 3, 5)), '05/03/2026');
      expect(formatDateShort(DateTime(2026, 12, 24)), '24/12/2026');
    });
  });

  group('formatDateRelative', () {
    final now = DateTime(2026, 10, 12, 18);

    test('knows today and yesterday in both languages', () {
      expect(formatDateRelative(now, now, isAr: true), 'اليوم');
      expect(formatDateRelative(now, now, isAr: false), "aujourd'hui");
      expect(
        formatDateRelative(DateTime(2026, 10, 11), now, isAr: true),
        'أمس',
      );
      expect(
        formatDateRelative(DateTime(2026, 10, 11), now, isAr: false),
        'hier',
      );
    });

    test('falls back to a numeric date', () {
      expect(
        formatDateRelative(DateTime(2026, 10, 5), now, isAr: true),
        '05/10/2026',
      );
    });
  });
}
