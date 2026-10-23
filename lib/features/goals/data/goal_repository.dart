import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/goal.dart';

/// Savings envelopes. Deposits/withdrawals move money between a regular
/// account and the goal **without** creating a ledger transaction (the money
/// was already spent/moved once).
class GoalRepository {
  GoalRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(AppConstants.colGoals);

  DocumentReference<Map<String, dynamic>> _account(String uid, String id) => _db
      .collection('users')
      .doc(uid)
      .collection(AppConstants.colAccounts)
      .doc(id);

  Stream<List<Goal>> watch(String uid) => _col(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Goal.fromDoc).toList());

  Future<void> create(String uid, Goal goal) async {
    final ref = _col(uid).doc(goal.id.isEmpty ? null : goal.id);
    await ref.set(goal.toMap());
  }

  Future<void> update(String uid, Goal goal) =>
      _col(uid).doc(goal.id).set(goal.toMap(), SetOptions(merge: true));

  Future<void> delete(String uid, String goalId) =>
      _col(uid).doc(goalId).delete();

  /// Moves [amount] from [accountId] into the goal envelope (one batch).
  Future<void> deposit({
    required String uid,
    required Goal goal,
    required int amount,
    required String accountId,
    DateTime? date,
    String note = '',
  }) async {
    final entry = GoalEntry(
      amount: amount,
      date: date ?? DateTime.now(),
      note: note,
    ).toMap();

    final batch = _db.batch();
    batch.update(_col(uid).doc(goal.id), {
      'savedAmount': FieldValue.increment(amount),
      'entries': FieldValue.arrayUnion([entry]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_account(uid, accountId), {
      'balance': FieldValue.increment(-amount),
    });
    await batch.commit();
  }

  /// Takes [amount] back out of the goal into [accountId] (one batch).
  Future<void> withdraw({
    required String uid,
    required Goal goal,
    required int amount,
    required String accountId,
    DateTime? date,
    String note = '',
  }) async {
    final entry = GoalEntry(
      amount: amount,
      date: date ?? DateTime.now(),
      note: note,
      withdraw: true,
    ).toMap();

    final batch = _db.batch();
    batch.update(_col(uid).doc(goal.id), {
      'savedAmount': FieldValue.increment(-amount),
      'entries': FieldValue.arrayUnion([entry]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_account(uid, accountId), {
      'balance': FieldValue.increment(amount),
    });
    await batch.commit();
  }
}
