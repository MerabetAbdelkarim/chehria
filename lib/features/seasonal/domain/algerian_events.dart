/// Algerian seasonal events used for early planning (Ramadan, school year...).
///
/// Hijri-based dates (Ramadan, Aïd) change every year; the table below holds
/// Maghrib-announced Gregorian approximations for Algeria until 2030. Later
/// years are extrapolated with the mean lunar year (±2 days), which is enough
/// for planning savings months ahead. The rest are fixed Gregorian dates.
library;

/// Known Ramadan starts in Algeria (Maghrib announcements, ±1 day).
final Map<int, DateTime> ramadanStarts = {
  2025: DateTime(2025, 3, 1),
  2026: DateTime(2026, 2, 18),
  2027: DateTime(2027, 2, 8),
  2028: DateTime(2028, 1, 28),
  2029: DateTime(2029, 1, 16),
  2030: DateTime(2030, 1, 6),
};

/// Mean length of the Hijri year in days.
const double lunarYearDays = 354.36707;

/// Every Ramadan start falling in Gregorian [year], soonest first.
///
/// Uses [ramadanStarts] when the date is known, otherwise steps forward from
/// the last known start by whole lunar years. A Gregorian year can contain
/// two Ramadans (2030: January and December).
List<DateTime> ramadanStartsIn(int year) {
  final known = ramadanStarts.values.toList()..sort();
  final anchor = known.last;
  final result = [
    for (final d in known)
      if (d.year == year) d,
  ];
  if (year < anchor.year) return result;

  for (var n = 1; ; n++) {
    final days = (n * lunarYearDays).round();
    final d = DateTime(anchor.year, anchor.month, anchor.day + days);
    if (d.year > year) break;
    if (d.year == year) result.add(d);
  }
  result.sort();
  return result;
}

/// One upcoming event the user can prepare for.
class SeasonalEvent {
  const SeasonalEvent({
    required this.id,
    required this.nameAr,
    required this.nameFr,
    required this.date,
  });

  final String id;
  final String nameAr;
  final String nameFr;
  final DateTime date;

  String name({required bool isAr}) => isAr ? nameAr : nameFr;
}

/// Events in the next [horizonMonths] months, soonest first.
List<SeasonalEvent> upcomingEvents(DateTime now, {int horizonMonths = 14}) {
  final cutoff = DateTime(now.year, now.month + horizonMonths);
  final events = <SeasonalEvent>[];

  void add(String id, String ar, String fr, DateTime date) {
    if (!date.isBefore(now) && date.isBefore(cutoff)) {
      events.add(SeasonalEvent(id: id, nameAr: ar, nameFr: fr, date: date));
    }
  }

  for (final year in [now.year - 1, now.year, now.year + 1, now.year + 2]) {
    final ramadans = ramadanStartsIn(year);
    for (var i = 0; i < ramadans.length; i++) {
      final ramadan = ramadans[i];
      // The first one keeps the historical id so linked goals stay linked.
      final suffix = i == 0 ? '$year' : '${year}b';
      add(
        'ramadan_$suffix',
        'بداية رمضان $year',
        'Début du Ramadan $year',
        ramadan,
      );
      add(
        'eid_$suffix',
        'عيد الفطر ${ramadan.add(const Duration(days: 30)).year}',
        'Aïd el-Fitr ${ramadan.add(const Duration(days: 30)).year}',
        ramadan.add(const Duration(days: 30)),
      );
    }
    add(
      'school_${year + 1}',
      'العودة للمدرسة ${year + 1}',
      'Rentrée scolaire ${year + 1}',
      DateTime(year, 9, 1),
    );
    add(
      'summer_$year',
      'العطلة الصيفية $year',
      "Vacances d'été $year",
      DateTime(year, 7, 1),
    );
    add(
      'november_$year',
      'أول نوفمبر $year',
      '1er Novembre $year',
      DateTime(year, 11, 1),
    );
    add(
      'newyear_${year + 1}',
      'رأس السنة ${year + 1}',
      'Nouvel An ${year + 1}',
      DateTime(year + 1, 1, 1),
    );
  }

  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
}

/// Whole months between [now] and [date], minimum 1 (for set-aside math).
int monthsLeft(DateTime now, DateTime date) {
  if (!date.isAfter(now)) return 1;
  var months = (date.year - now.year) * 12 + (date.month - now.month);
  if (date.day < now.day) months -= 1;
  return months < 1 ? 1 : months;
}

/// Dinars to put aside each month to reach [target] by [date].
int monthlySetAside({
  required int target,
  required int saved,
  required DateTime now,
  required DateTime date,
}) {
  final remaining = target - saved;
  if (remaining <= 0) return 0;
  return (remaining / monthsLeft(now, date)).ceil();
}

/// Days left until [date] (never negative).
int daysLeft(DateTime now, DateTime date) {
  final a = DateTime(now.year, now.month, now.day);
  final b = DateTime(date.year, date.month, date.day);
  final diff = b.difference(a).inDays;
  return diff < 0 ? 0 : diff;
}
