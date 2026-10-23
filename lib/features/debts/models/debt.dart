import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/debt_calculator.dart';

/// Direction of the debt.
enum DebtType {
  /// Debts **I owe** to other people.
  iOwe,

  /// Debts **owed to me** by other people.
  owedToMe;

  static DebtType fromId(String? id) => DebtType.values.firstWhere(
    (t) => t.name == id,
    orElse: () => DebtType.iOwe,
  );
}

/// One partial payment recorded against a debt.
class DebtPayment {
  const DebtPayment({
    required this.amount,
    required this.date,
    this.note = '',
    this.id = '',
  });

  /// Matches `linkedPaymentId` on the ledger operation. Empty for payments
  /// recorded before ids existed.
  final String id;
  final int amount;
  final DateTime date;
  final String note;

  factory DebtPayment.fromMap(Map<String, dynamic> m) => DebtPayment(
    id: m['id'] as String? ?? '',
    amount: (m['amount'] as num?)?.toInt() ?? 0,
    date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    note: m['note'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'note': note,
  };
}

/// A debt of either direction, with its partial payment history.
class Debt {
  const Debt({
    required this.id,
    required this.type,
    required this.person,
    required this.amount,
    required this.date,
    this.phone,
    this.dueDate,
    this.note = '',
    this.payments = const [],
    this.addToBalance = false,
    this.balanceAccountId,
    this.createdAt,
  });

  final String id;
  final DebtType type;
  final String person;
  final String? phone;

  /// Total amount in dinars (integer).
  final int amount;
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final List<DebtPayment> payments;

  /// Whether the borrowed/lent amount moved the account balance on creation.
  final bool addToBalance;

  /// Account moved by [addToBalance], so deleting the debt can move it back.
  final String? balanceAccountId;
  final DateTime? createdAt;

  int get paidTotal => debtPaidTotal(payments.map((p) => p.amount));
  int get remaining => debtRemaining(amount, payments.map((p) => p.amount));
  bool get isSettled => isDebtSettled(remaining);
  bool isDueBefore(DateTime payday) =>
      isDebtDueBefore(dueDate: dueDate, dueBefore: payday);

  bool isOld(DateTime now) =>
      isOldDebt(date: date, now: now, remaining: remaining);

  Debt copyWith({List<DebtPayment>? payments}) => Debt(
    id: id,
    type: type,
    person: person,
    phone: phone,
    amount: amount,
    date: date,
    dueDate: dueDate,
    note: note,
    payments: payments ?? this.payments,
    addToBalance: addToBalance,
    balanceAccountId: balanceAccountId,
    createdAt: createdAt,
  );

  factory Debt.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Debt(
      id: doc.id,
      type: DebtType.fromId(d['type'] as String?),
      person: d['person'] as String? ?? '',
      phone: d['phone'] as String?,
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      note: d['note'] as String? ?? '',
      payments: ((d['payments'] as List?) ?? const [])
          .map((e) => DebtPayment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      addToBalance: d['addToBalance'] as bool? ?? false,
      balanceAccountId: d['balanceAccountId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'person': person,
    'phone': phone,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'note': note,
    'payments': payments.map((p) => p.toMap()).toList(),
    'addToBalance': addToBalance,
    if (balanceAccountId != null) 'balanceAccountId': balanceAccountId,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
