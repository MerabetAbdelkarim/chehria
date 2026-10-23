import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../dart/models/dart_group.dart';
import '../../debts/models/debt.dart';
import '../../subscriptions/domain/subscription_calculator.dart';
import '../../subscriptions/models/subscription.dart';
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

  DocumentReference<Map<String, dynamic>> _userDoc(
    String uid,
    String collection,
    String id,
  ) => _db.collection('users').doc(uid).collection(collection).doc(id);

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

  /// The most recent operations, for the transactions screen. The screen
  /// grows [limit] page by page as the user scrolls.
  Stream<List<MoneyTransaction>> watchRecent(
    String uid, {
    int limit = AppConstants.transactionsPageSize,
  }) => _col(uid)
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
  Future<void> update(String uid, MoneyTransaction edited) async {
    final ref = _col(uid).doc(edited.id);
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final old = MoneyTransaction.fromDoc(snapshot);

    // The amount and direction of a linked operation belong to its debt,
    // subscription or dawra: only the free fields may change here.
    final txn = old.isLinked
        ? edited.copyWith(type: old.type, amount: old.amount)
        : edited;

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

  /// Deletes the operation, gives the money back to the accounts and undoes
  /// its effect on the linked debt / subscription / dawra — one batch.
  Future<void> delete(String uid, MoneyTransaction txn) async {
    final batch = _db.batch();
    batch.delete(_col(uid).doc(txn.id));
    _applyDeltas(batch, uid, balanceDeltas(txn), invert: true);
    await _undoLink(batch, uid, txn);
    await batch.commit();
  }

  Future<void> _undoLink(
    WriteBatch batch,
    String uid,
    MoneyTransaction txn,
  ) async {
    final linkedId = txn.linkedId;
    if (linkedId == null) return;

    switch (txn.source) {
      case TxnSource.debt:
        final ref = _userDoc(uid, AppConstants.colDebts, linkedId);
        final snap = await ref.get();
        if (!snap.exists) return; // debt already deleted: nothing to undo
        final debt = Debt.fromDoc(snap);
        final kept = debt.payments
            .where((p) => p.id.isEmpty || p.id != txn.linkedPaymentId)
            .toList();
        if (kept.length == debt.payments.length) return;
        batch.update(ref, {
          'payments': kept.map((p) => p.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

      case TxnSource.subscription:
        final previous = txn.previousDueDate;
        if (previous == null) return;
        final ref = _userDoc(uid, AppConstants.colSubscriptions, linkedId);
        final snap = await ref.get();
        if (!snap.exists) return;
        final sub = Subscription.fromDoc(snap);
        // Only rewind when no later payment moved the bill again.
        final producedByThis = dueAfterPayment(previous, sub.cycle, txn.date);
        if (sub.nextDueDate != producedByThis) return;
        batch.update(ref, {
          'nextDueDate': Timestamp.fromDate(previous),
          'updatedAt': FieldValue.serverTimestamp(),
        });

      case TxnSource.dawra:
        final ref = _userDoc(uid, AppConstants.colDart, linkedId);
        final snap = await ref.get();
        if (!snap.exists) return;
        final group = DartGroup.fromDoc(snap);
        if (txn.linkedPaymentId != null) {
          // A contribution: drop its payment entry.
          final kept = group.payments
              .where((p) => p.id.isEmpty || p.id != txn.linkedPaymentId)
              .toList();
          if (kept.length == group.payments.length) return;
          batch.update(ref, {
            'payments': kept.map((p) => p.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (txn.linkedRound != null &&
            group.currentRound == txn.linkedRound! + 1) {
          // The pot of the latest round: step the rotation back.
          batch.update(ref, {
            'currentRound': txn.linkedRound,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

      case TxnSource.manual:
      case TxnSource.salary:
        return;
    }
  }
}
