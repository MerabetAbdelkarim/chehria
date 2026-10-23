import 'package:cloud_firestore/cloud_firestore.dart';

/// What the goal is for.
enum GoalKind {
  /// Regular saving.
  saving,

  /// Tied to an Algerian seasonal event (Ramadan, school year, ...).
  seasonal;

  static GoalKind fromId(String? id) => GoalKind.values.firstWhere(
    (g) => g.name == id,
    orElse: () => GoalKind.saving,
  );
}

/// One deposit (or withdrawal) recorded against a goal.
class GoalEntry {
  const GoalEntry({
    required this.amount,
    required this.date,
    this.note = '',
    this.withdraw = false,
  });

  final int amount;
  final DateTime date;
  final String note;

  /// `true` when the money was taken back out of the envelope.
  final bool withdraw;

  factory GoalEntry.fromMap(Map<String, dynamic> m) => GoalEntry(
    amount: (m['amount'] as num?)?.toInt() ?? 0,
    date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    note: m['note'] as String? ?? '',
    withdraw: m['withdraw'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'note': note,
    'withdraw': withdraw,
  };
}

/// A savings goal ("envelope"). Money reserved here was already **moved out**
/// of a regular account, so it never appears as an expense again.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    this.note = '',
    this.kind = GoalKind.saving,
    this.eventId,
    this.entries = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final int targetAmount;
  final int savedAmount;
  final DateTime? deadline;
  final String note;
  final GoalKind kind;

  /// Seasonal goals link back to the preset event that created them.
  final String? eventId;
  final List<GoalEntry> entries;
  final DateTime? createdAt;

  double get progress {
    if (targetAmount <= 0) return 0;
    final ratio = savedAmount / targetAmount;
    return ratio.clamp(0.0, 1.0);
  }

  bool get isCompleted => targetAmount > 0 && savedAmount >= targetAmount;

  int get remaining {
    if (targetAmount <= 0) return 0;
    final rest = targetAmount - savedAmount;
    return rest < 0 ? 0 : rest;
  }

  factory Goal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Goal(
      id: doc.id,
      name: d['name'] as String? ?? '',
      targetAmount: (d['targetAmount'] as num?)?.toInt() ?? 0,
      savedAmount: (d['savedAmount'] as num?)?.toInt() ?? 0,
      deadline: (d['deadline'] as Timestamp?)?.toDate(),
      note: d['note'] as String? ?? '',
      kind: GoalKind.fromId(d['kind'] as String?),
      eventId: d['eventId'] as String?,
      entries: ((d['entries'] as List?) ?? const [])
          .map((e) => GoalEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    'note': note,
    'kind': kind.name,
    'eventId': eventId,
    'entries': entries.map((e) => e.toMap()).toList(),
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
