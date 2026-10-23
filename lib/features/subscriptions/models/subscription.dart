import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/subscription_calculator.dart';

/// A recurring bill (phone, internet, streaming, rent…).
///
/// [amount] is a **positive integer in dinars**. The dashboard subtracts the
/// unpaid bills falling due before the next pay day from the remaining amount.
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    required this.nextDueDate,
    this.categoryId,
    this.accountId,
    this.isActive = true,
    this.note = '',
    this.lastPaidAt,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Positive integer in dinars.
  final int amount;
  final SubscriptionCycle cycle;
  final DateTime nextDueDate;
  final String? categoryId;

  /// Account debited when the bill is paid (the UI falls back to the default
  /// account when this is null).
  final String? accountId;
  final bool isActive;
  final String note;
  final DateTime? lastPaidAt;
  final DateTime? createdAt;

  bool dueBefore(DateTime limit) => isActive && isDueBefore(nextDueDate, limit);
  bool isOverdueNow(DateTime now) => isActive && isOverdue(nextDueDate, now);
  bool isDueTodayNow(DateTime now) => isActive && isDueToday(nextDueDate, now);

  /// Day label used by the UI: overdue / today / tomorrow / date.
  int daysUntilNow(DateTime now) => daysUntil(nextDueDate, now);

  Subscription copyWith({
    String? name,
    int? amount,
    SubscriptionCycle? cycle,
    DateTime? nextDueDate,
    String? categoryId,
    String? accountId,
    bool? isActive,
    String? note,
    DateTime? lastPaidAt,
  }) => Subscription(
    id: id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    cycle: cycle ?? this.cycle,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    isActive: isActive ?? this.isActive,
    note: note ?? this.note,
    lastPaidAt: lastPaidAt ?? this.lastPaidAt,
    createdAt: createdAt,
  );

  factory Subscription.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Subscription(
      id: doc.id,
      name: d['name'] as String? ?? '',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      cycle: SubscriptionCycle.fromId(d['cycle'] as String?),
      nextDueDate: (d['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categoryId: d['categoryId'] as String?,
      accountId: d['accountId'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      note: d['note'] as String? ?? '',
      lastPaidAt: (d['lastPaidAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'cycle': cycle.name,
    'nextDueDate': Timestamp.fromDate(nextDueDate),
    'categoryId': categoryId,
    'accountId': accountId,
    'isActive': isActive,
    'note': note,
    'lastPaidAt': lastPaidAt != null ? Timestamp.fromDate(lastPaidAt!) : null,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
