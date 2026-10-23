import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../transactions/models/money_transaction.dart';
import '../models/account.dart';

/// Accounts/wallets: balances are stored on the document and updated with
/// `FieldValue.increment` inside the same batch as the related transaction.
class AccountRepository {
  AccountRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(AppConstants.colAccounts);

  Stream<List<Account>> watch(String uid) => _col(uid)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Account.fromDoc).toList());

  Future<List<Account>> readAll(String uid) async {
    final snapshot = await _col(uid).orderBy('name').get();
    return snapshot.docs.map(Account.fromDoc).toList();
  }

  Future<void> create(String uid, Account account) => _col(
    uid,
  ).doc(account.id.isEmpty ? null : account.id).set(account.toMap());

  Future<void> update(String uid, Account account) =>
      _col(uid).doc(account.id).set(account.toMap(), SetOptions(merge: true));

  /// Whether the account already carries operations (blocks deletion).
  Future<bool> isInUse(String uid, String accountId) async {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection(AppConstants.colTransactions);
    Future<bool> has(String field) async {
      final snap = await col.where(field, isEqualTo: accountId).limit(1).get();
      return snap.docs.isNotEmpty;
    }

    return await has('accountId') ||
        await has('fromAccountId') ||
        await has('toAccountId');
  }

  Future<void> delete(String uid, String accountId) =>
      _col(uid).doc(accountId).delete();

  /// Moves [amount] dinars between two accounts and records the transfer as a
  /// transaction — all in a **single batch**.
  Future<void> transfer({
    required String uid,
    required String fromId,
    required String toId,
    required int amount,
    String note = '',
    DateTime? date,
  }) async {
    final db = _db;
    final userDoc = db.collection('users').doc(uid);
    final txnRef = userDoc.collection(AppConstants.colTransactions).doc();
    final now = date ?? DateTime.now();

    final txn = MoneyTransaction(
      id: txnRef.id,
      type: TxnType.transfer,
      amount: amount,
      date: now,
      accountId: fromId,
      fromAccountId: fromId,
      toAccountId: toId,
      note: note,
    );

    final batch = db.batch();
    batch.update(userDoc.collection(AppConstants.colAccounts).doc(fromId), {
      'balance': FieldValue.increment(-amount),
    });
    batch.update(userDoc.collection(AppConstants.colAccounts).doc(toId), {
      'balance': FieldValue.increment(amount),
    });
    batch.set(txnRef, txn.toMap());
    await batch.commit();
  }
}
