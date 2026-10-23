import 'package:cloud_firestore/cloud_firestore.dart';

/// Where the money sits: cash, CCP/BaridiMob, bank card...
enum AccountType {
  cash,
  ccp,
  card,
  other;

  static AccountType fromId(String? id) => AccountType.values.firstWhere(
    (t) => t.name == id,
    orElse: () => AccountType.other,
  );
}

/// A wallet with its own **integer** balance in dinars.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.colorValue = 0xFF00873D,
    this.createdAt,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Current balance in dinars (can be negative only through transfers).
  final int balance;
  final int colorValue;
  final DateTime? createdAt;

  Account copyWith({
    String? name,
    AccountType? type,
    int? balance,
    int? colorValue,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }

  factory Account.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Account(
      id: doc.id,
      name: d['name'] as String? ?? '',
      type: AccountType.fromId(d['type'] as String?),
      balance: (d['balance'] as num?)?.toInt() ?? 0,
      colorValue: (d['colorValue'] as num?)?.toInt() ?? 0xFF00873D,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'balance': balance,
    'colorValue': colorValue,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
