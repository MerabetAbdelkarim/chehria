import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../transactions/models/money_transaction.dart';
import '../domain/subscription_calculator.dart';
import '../models/subscription.dart';

/// Recurring bills with a "pay now" action that keeps the ledger correct.
class SubscriptionRepository {
  SubscriptionRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection(AppConstants.colSubscriptions);

  DocumentReference<Map<String, dynamic>> _account(String uid, String id) => _db
      .collection('users')
      .doc(uid)
      .collection(AppConstants.colAccounts)
      .doc(id);

  Stream<List<Subscription>> watch(String uid) => _col(uid)
      .orderBy('nextDueDate')
      .snapshots()
      .map((s) => s.docs.map(Subscription.fromDoc).toList());

  Future<void> create(String uid, Subscription sub) =>
      _col(uid).doc(sub.id.isEmpty ? null : sub.id).set(sub.toMap());

  Future<void> update(String uid, Subscription sub) =>
      _col(uid).doc(sub.id).set(sub.toMap(), SetOptions(merge: true));

  Future<void> delete(String uid, String subId) =>
      _col(uid).doc(subId).delete();

  Future<void> setActive(String uid, String subId, bool active) =>
      _col(uid).doc(subId).set({
        'isActive': active,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Pays the bill once:
  /// - an **expense** operation tagged `source: subscription`,
  /// - the account balance decremented,
  /// - `nextDueDate` advanced one cycle, `lastPaidAt` set.
  ///
  /// All three land in a single batch. The operation remembers the previous
  /// due date so deleting it puts the bill back where it was.
  Future<void> recordPayment({
    required String uid,
    required Subscription sub,
    required String accountId,
    DateTime? date,
  }) async {
    final paidAt = date ?? DateTime.now();
    final txnRef = _db
        .collection('users')
        .doc(uid)
        .collection(AppConstants.colTransactions)
        .doc();

    final txn = MoneyTransaction(
      id: txnRef.id,
      type: TxnType.expense,
      amount: sub.amount,
      date: paidAt,
      accountId: accountId,
      categoryId: sub.categoryId,
      note: sub.name,
      source: TxnSource.subscription,
      linkedId: sub.id,
      previousDueDate: sub.nextDueDate,
    );

    final batch = _db.batch();
    batch.set(txnRef, txn.toMap());
    batch.set(_col(uid).doc(sub.id), {
      'nextDueDate': Timestamp.fromDate(
        dueAfterPayment(sub.nextDueDate, sub.cycle, paidAt),
      ),
      'lastPaidAt': Timestamp.fromDate(paidAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.update(_account(uid, accountId), {
      'balance': FieldValue.increment(-sub.amount),
    });
    await batch.commit();
  }
}
