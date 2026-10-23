import 'package:cloud_firestore/cloud_firestore.dart';

/// Income, expense or an internal transfer between the user's own accounts.
enum TxnType {
  income,
  expense,
  transfer;

  static TxnType fromId(String? id) => TxnType.values.firstWhere(
    (t) => t.name == id,
    orElse: () => TxnType.expense,
  );
}

/// Where the operation came from (used to keep the dashboard formula correct:
/// a recorded salary is *not* counted as "extra income").
enum TxnSource {
  manual,
  subscription,
  debt,
  salary;

  static TxnSource fromId(String? id) => TxnSource.values.firstWhere(
    (t) => t.name == id,
    orElse: () => TxnSource.manual,
  );
}

/// An income/expense/transfer record.
///
/// [amount] is always a **positive integer in dinars**; the sign is carried by
/// [type].
class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.note = '',
    this.source = TxnSource.manual,
    this.createdAt,
  });

  final String id;
  final TxnType type;
  final int amount;
  final DateTime date;
  final String? categoryId;
  final String? accountId;

  /// Transfers only.
  final String? fromAccountId;
  final String? toAccountId;

  final String note;
  final TxnSource source;
  final DateTime? createdAt;

  bool get isIncome => type == TxnType.income;
  bool get isExpense => type == TxnType.expense;
  bool get isTransfer => type == TxnType.transfer;

  /// Same operation, identified by a Firestore document id.
  MoneyTransaction withId(String newId) => MoneyTransaction(
    id: newId,
    type: type,
    amount: amount,
    date: date,
    categoryId: categoryId,
    accountId: accountId,
    fromAccountId: fromAccountId,
    toAccountId: toAccountId,
    note: note,
    source: source,
    createdAt: createdAt,
  );

  /// Balance change applied to [accountId] for this operation.
  int deltaFor(String accountId) {
    if (type == TxnType.transfer) {
      if (fromAccountId == accountId) return -amount;
      if (toAccountId == accountId) return amount;
      return 0;
    }
    if (accountId == this.accountId) return isIncome ? amount : -amount;
    return 0;
  }

  MoneyTransaction copyWith({
    TxnType? type,
    int? amount,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    String? note,
    TxnSource? source,
  }) {
    return MoneyTransaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt,
    );
  }

  factory MoneyTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return MoneyTransaction(
      id: doc.id,
      type: TxnType.fromId(d['type'] as String?),
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categoryId: d['categoryId'] as String?,
      accountId: d['accountId'] as String?,
      fromAccountId: d['fromAccountId'] as String?,
      toAccountId: d['toAccountId'] as String?,
      note: d['note'] as String? ?? '',
      source: TxnSource.fromId(d['source'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'categoryId': categoryId,
    'accountId': accountId,
    'fromAccountId': fromAccountId,
    'toAccountId': toAccountId,
    'note': note,
    'source': source.name,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
