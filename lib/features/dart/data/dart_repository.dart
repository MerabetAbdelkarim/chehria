import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../transactions/models/money_transaction.dart';
import '../models/dart_group.dart';

/// Rotating savings groups. Contributions are expenses, receiving the pot is
/// an income — both written together with the account balance in one batch.
class DartRepository {
  DartRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(AppConstants.colDart);

  DocumentReference<Map<String, dynamic>> _account(String uid, String id) => _db
      .collection('users')
      .doc(uid)
      .collection(AppConstants.colAccounts)
      .doc(id);

  DocumentReference<Map<String, dynamic>> _txnRef(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection(AppConstants.colTransactions)
      .doc();

  Stream<List<DartGroup>> watch(String uid) => _col(uid)
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(DartGroup.fromDoc).toList());

  Future<void> create(String uid, DartGroup group) async {
    final ref = _col(uid).doc(group.id.isEmpty ? null : group.id);
    await ref.set(group.toMap());
  }

  Future<void> update(String uid, DartGroup group) =>
      _col(uid).doc(group.id).set(group.toMap(), SetOptions(merge: true));

  Future<void> delete(String uid, String groupId) =>
      _col(uid).doc(groupId).delete();

  /// Records a member's contribution for [round]: expense + payments entry.
  /// [note] is the localized label written on the ledger operation.
  Future<void> payContribution({
    required String uid,
    required DartGroup group,
    required String memberName,
    required String accountId,
    required String note,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final txnRef = _txnRef(uid);
    final txn = MoneyTransaction(
      id: txnRef.id,
      type: TxnType.expense,
      amount: group.contributionAmount,
      date: now,
      accountId: accountId,
      categoryId: AppConstants.catDawra,
      note: note,
      source: TxnSource.dawra,
      linkedId: group.id,
      linkedPaymentId: txnRef.id,
      linkedRound: group.currentRound,
    );
    final payment = DartPayment(
      id: txnRef.id,
      memberName: memberName,
      round: group.currentRound,
      date: now,
    ).toMap();

    final batch = _db.batch();
    batch.set(txnRef, txn.toMap());
    batch.update(_col(uid).doc(group.id), {
      'payments': FieldValue.arrayUnion([payment]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_account(uid, accountId), {
      'balance': FieldValue.increment(-group.contributionAmount),
    });
    await batch.commit();
  }

  /// The pot is handed to the current receiver and the dawra advances:
  /// - [toMe]     -> **income** (I received the pot)
  /// - otherwise  -> **expense** (I handed the cash to that member)
  Future<void> receiveRound({
    required String uid,
    required DartGroup group,
    required String accountId,
    required String receiverName,
    required bool toMe,
    required String note,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final txnRef = _txnRef(uid);
    final txn = MoneyTransaction(
      id: txnRef.id,
      type: toMe ? TxnType.income : TxnType.expense,
      amount: group.pot,
      date: now,
      accountId: accountId,
      categoryId: AppConstants.catDawra,
      note: note,
      source: TxnSource.dawra,
      linkedId: group.id,
      linkedRound: group.currentRound,
    );

    final batch = _db.batch();
    batch.set(txnRef, txn.toMap());
    batch.update(_col(uid).doc(group.id), {
      'currentRound': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_account(uid, accountId), {
      'balance': FieldValue.increment(toMe ? group.pot : -group.pot),
    });
    await batch.commit();
  }
}
