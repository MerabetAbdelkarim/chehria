import 'package:cloud_firestore/cloud_firestore.dart';

/// A monthly spending limit for one category.
///
/// The document id is `<month>_<categoryId>` so saving the same pair again
/// simply upserts the limit.
class Budget {
  const Budget({
    required this.id,
    required this.month,
    required this.categoryId,
    required this.limit,
    this.createdAt,
  });

  final String id;

  /// Month key `YYYY-MM`.
  final String month;
  final String categoryId;

  /// Monthly ceiling in dinars (integer, positive).
  final int limit;
  final DateTime? createdAt;

  /// `2026-10` for any date inside October 2026.
  static String monthKeyOf(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// First instant of a `YYYY-MM` key.
  static DateTime monthStart(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// First instant of the month **after** the key (exclusive end of range).
  static DateTime monthEnd(String key) {
    final start = monthStart(key);
    return DateTime(start.year, start.month + 1);
  }

  /// `addMonths(1)` on a month key, e.g. `2026-12` -> `2027-01`.
  static String addMonths(String key, int delta) {
    final start = monthStart(key);
    final next = DateTime(start.year, start.month + delta);
    return monthKeyOf(next);
  }

  factory Budget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Budget(
      id: doc.id,
      month: d['month'] as String? ?? '',
      categoryId: d['categoryId'] as String? ?? '',
      limit: (d['limit'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'month': month,
    'categoryId': categoryId,
    'limit': limit,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
