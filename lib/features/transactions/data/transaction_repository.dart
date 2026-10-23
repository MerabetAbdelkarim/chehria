import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/money_transaction.dart';

/// Income/expense/transfer records.
///
/// Every mutation keeps the affected account balances in sync using a single
/// **batched write** (transaction document + `FieldValue.increment`).
class TransactionRepository {
  TransactionRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(AppConstants.colTransactions);

  DocumentReference<Map<String, dynamic>> _account(String uid, String id) => _db
      .collection('users')
      .doc(uid)
      .collection(AppConstants.colAccounts)
      .doc(id);

  /// Operations inside `[start, end)` ordered by date (newest first).
  Stream<List<MoneyTransaction>> watchRange(
    String uid,
    DateTime start,
    DateTime end,
  ) {
    return _col(uid)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          isLessThan: Timestamp.fromDate(end),
        )
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(MoneyTransaction.fromDoc).toList());
  }

  /// The most recent operations, for the transactions screen.
  Stream<List<MoneyTransaction>> watchRecent(String uid, {int limit = 300}) =>
      _col(uid)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(MoneyTransaction.fromDoc).toList());

  /// Per-account balance changes implied by [t].
  static Map<String, int> balanceDeltas(MoneyTransaction t) {
    final deltas = <String, int>{};
    void add(String? id, int value) {
      if (id == null || value == 0) return;
      deltas[id] = (deltas[id] ?? 0) + value;
    }

    if (t.isTransfer) {
      add(t.fromAccountId, -t.amount);
      add(t.toAccountId, t.amount);
    } else {
      add(t.accountId, t.isIncome ? t.amount : -t.amount);
    }
    return deltas;
  }

  void _applyDeltas(
    WriteBatch batch,
    String uid,
    Map<String, int> deltas, {
    bool invert = false,
  }) {
    deltas.forEach((accountId, delta) {
      final value = invert ? -delta : delta;
      if (value == 0) return;
      batch.update(_account(uid, accountId), {
        'balance': FieldValue.increment(value),
      });
    });
  }

  /// Creates the operation and moves the money (one batch).
  Future<String> add(String uid, MoneyTransaction txn) async {
    final txnRef = _col(uid).doc();
    final batch = _db.batch();
    batch.set(txnRef, txn.withId(txnRef.id).toMap());
    _applyDeltas(batch, uid, balanceDeltas(txn));
    await batch.commit();
    return txnRef.id;
  }

  /// Updates an existing operation, adjusting every affected balance.
  Future<void> update(String uid, MoneyTransaction txn) async {
    final ref = _col(uid).doc(txn.id);
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final old = MoneyTransaction.fromDoc(snapshot);

    final combined = <String, int>{};
    void merge(String key, int value) =>
        combined[key] = (combined[key] ?? 0) + value;
    balanceDeltas(txn).forEach(merge);
    balanceDeltas(old).forEach((k, v) => merge(k, -v));

    final batch = _db.batch();
    batch.set(ref, txn.toMap(), SetOptions(merge: true));
    _applyDeltas(batch, uid, combined);
    await batch.commit();
  }

  /// Deletes the operation and gives the money back to the accounts.
  Future<void> delete(String uid, MoneyTransaction txn) async {
    final batch = _db.batch();
    batch.delete(_col(uid).doc(txn.id));
    _applyDeltas(batch, uid, balanceDeltas(txn), invert: true);
    await batch.commit();
  }
}
