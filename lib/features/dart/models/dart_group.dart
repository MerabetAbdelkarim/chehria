import 'package:cloud_firestore/cloud_firestore.dart';

/// One contribution payment recorded for a member of a round.
class DartPayment {
  const DartPayment({
    required this.memberName,
    required this.round,
    required this.date,
    this.id = '',
  });

  /// Matches `linkedPaymentId` on the ledger operation (empty on old data).
  final String id;
  final String memberName;
  final int round;
  final DateTime date;

  factory DartPayment.fromMap(Map<String, dynamic> m) => DartPayment(
    id: m['id'] as String? ?? '',
    memberName: m['memberName'] as String? ?? '',
    round: (m['round'] as num?)?.toInt() ?? 1,
    date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'memberName': memberName,
    'round': round,
    'date': Timestamp.fromDate(date),
  };
}

/// A rotating savings group ("dawra"): every member pays the same monthly
/// contribution and one of them receives the whole pot each round.
class DartGroup {
  const DartGroup({
    required this.id,
    required this.name,
    required this.contributionAmount,
    required this.memberNames,
    required this.meName,
    required this.currentRound,
    required this.startDate,
    this.payments = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final int contributionAmount;

  /// Member names in rotation order.
  final List<String> memberNames;

  /// Which member in [memberNames] is me.
  final String meName;

  /// 1-based round currently being paid/received.
  final int currentRound;
  final DateTime startDate;
  final List<DartPayment> payments;
  final DateTime? createdAt;

  int get memberCount => memberNames.length;

  /// Who receives the pot in [round].
  String receiverOf(int round) {
    if (memberNames.isEmpty) return '';
    return memberNames[(round - 1) % memberNames.length];
  }

  String get nextReceiver => receiverOf(currentRound);

  /// Total pot of one full rotation.
  int get pot => contributionAmount * memberCount;

  /// Rounds already paid out (never negative).
  int get roundsDone {
    final done = currentRound - 1;
    return done < 0 ? 0 : done;
  }

  /// Once the last member received, the dawra is over.
  bool get isFinished => currentRound > memberCount;

  bool hasPaid(String memberName, int round) =>
      payments.any((p) => p.memberName == memberName && p.round == round);

  List<String> get unpaidMembers => [
    for (final member in memberNames)
      if (!hasPaid(member, currentRound)) member,
  ];

  factory DartGroup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return DartGroup(
      id: doc.id,
      name: d['name'] as String? ?? '',
      contributionAmount: (d['contributionAmount'] as num?)?.toInt() ?? 0,
      memberNames: ((d['memberNames'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      meName: d['meName'] as String? ?? '',
      currentRound: (d['currentRound'] as num?)?.toInt() ?? 1,
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      payments: ((d['payments'] as List?) ?? const [])
          .map((e) => DartPayment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'contributionAmount': contributionAmount,
    'memberNames': memberNames,
    'meName': meName,
    'currentRound': currentRound,
    'startDate': Timestamp.fromDate(startDate),
    'payments': payments.map((p) => p.toMap()).toList(),
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
