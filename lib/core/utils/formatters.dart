/// Number / amount / date formatting helpers.
///
/// All amounts are **integers in dinars**. Nothing in the app ever stores or
/// multiplies amounts as `double` (only divisions for display are done in
/// floating point, on already-integer values).
library;

import '../constants/app_constants.dart';

const List<String> _arMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> _frMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

const List<String> _arDays = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

const List<String> _frDays = [
  'dimanche',
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
];

/// Groups an integer with `,` every three digits (`1234567` -> `1,234,567`).
/// Western digits are used on purpose: they are the everyday digits in Algeria.
String groupNumber(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

String _trimDouble(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(2);
  return s.endsWith('0')
      ? (s.endsWith('.00')
            ? s.substring(0, s.length - 3)
            : s.substring(0, s.length - 1))
      : s;
}

/// Standard display: `12,500 دج`.
String formatDzd(int amount) =>
    '${groupNumber(amount)} ${AppConstants.currencySymbol}';

/// Algerian way of quoting money in **millions of centimes**:
/// `10,000 DA = 1 مليون` (1 million centimes), `100 DA = 10 ألف`.
///
/// Falls back to plain dinars for very small amounts.
String formatDzdAlgerian(int amount) {
  final sign = amount < 0 ? '-' : '';
  final abs = amount.abs();
  if (abs >= 10000) {
    return '$sign${_trimDouble(abs / 10000)} مليون';
  }
  if (abs >= 10) {
    return '$sign${_trimDouble(abs / 10)} ألف';
  }
  return '$sign${groupNumber(abs)} ${AppConstants.currencySymbol}';
}

/// Picks the formatter matching the user's currency display setting.
String formatAmount(int amount, {required bool millionsMode}) =>
    millionsMode ? formatDzdAlgerian(amount) : formatDzd(amount);

/// `+1,500` / `-1,500` (no currency symbol, for compact deltas).
String formatSigned(int amount, {required bool millionsMode}) {
  final core = millionsMode
      ? formatDzdAlgerian(amount.abs())
      : groupNumber(amount.abs());
  return amount < 0 ? '-$core' : '+$core';
}

/// `12/10/2026`
String formatDateShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// `12 أكتوبر 2026` / `12 octobre 2026`
String formatDateLong(DateTime d, {required bool isAr}) {
  final months = isAr ? _arMonths : _frMonths;
  return isAr
      ? '${d.day} ${months[d.month - 1]} ${d.year}'
      : '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// `أكتوبر 2026` / `octobre 2026`
String monthLabel(int year, int month, {required bool isAr}) {
  final months = isAr ? _arMonths : _frMonths;
  return '${months[month - 1]} $year';
}

/// `26/10 -> 01/11`
String formatRange(DateTime start, DateTime end) =>
    '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}'
    ' → '
    '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';

/// Weekday name, e.g. `الجمعة` / `vendredi`.
String dayName(DateTime d, {required bool isAr}) =>
    (isAr ? _arDays : _frDays)[d.weekday % 7];

/// `اليوم` / `أمس` when applicable, otherwise a formatted date.
String formatDateRelative(DateTime d, DateTime now, {required bool isAr}) {
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return isAr ? 'اليوم' : "aujourd'hui";
  if (diff == 1) return isAr ? 'أمس' : 'hier';
  return formatDateShort(d);
}

/// Percentage string with no decimals when whole (`%12` / `12%`).
String formatPercent(double ratio, {required bool isAr}) {
  final value = (ratio * 100);
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return isAr ? '%$text' : '$text%';
}
