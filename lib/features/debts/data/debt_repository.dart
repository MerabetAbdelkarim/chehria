import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../transactions/models/money_transaction.dart';
import '../models/debt.dart';

/// Debts of both directions (`iOwe` / `owedToMe`) with partial payments.
///
/// Recording a payment always writes the payment **and** the matching income /
/// expense transaction **and** the account balance in one batched write.
class DebtRepository {
  DebtRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(AppConstants.colDebts);

  DocumentReference<Map<String, dynamic>> _account(String uid, String id) => _db
      .collection('users')
      .doc(uid)
      .collection(AppConstants.colAccounts)
      .doc(id);

  Stream<List<Debt>> watch(String uid) => _col(uid)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Debt.fromDoc).toList());

  Future<void> create(String uid, Debt debt, {String? balanceAccountId}) async {
    final ref = _col(uid).doc(debt.id.isEmpty ? null : debt.id);
    final batch = _db.batch();
    batch.set(ref, debt.toMap());

    if (debt.addToBalance && balanceAccountId != null) {
      // Borrowing adds money to my balance, lending takes mine away.
      final delta = debt.type == DebtType.iOwe ? debt.amount : -debt.amount;
      if (delta != 0) {
        batch.update(_account(uid, balanceAccountId), {
          'balance': FieldValue.increment(delta),
        });
      }
    }
    await batch.commit();
  }

  Future<void> update(String uid, Debt debt) =>
      _col(uid).doc(debt.id).set(debt.toMap(), SetOptions(merge: true));

  Future<void> delete(String uid, String debtId) =>
      _col(uid).doc(debtId).delete();

  /// Adds a partial payment:
  /// - `iOwe`      -> an **expense** (I gave money back)
  /// - `owedToMe`  -> an **income**  (I received money)
  ///
  /// One batch: transaction + debt payments array + account balance.
  Future<void> addPayment({
    required String uid,
    required Debt debt,
    required int amount,
    required String accountId,
    DateTime? date,
    String note = '',
  }) async {
    final now = date ?? DateTime.now();
    final received = debt.type == DebtType.owedToMe;

    final txnRef = _db
        .collection('users')
        .doc(uid)
        .collection(AppConstants.colTransactions)
        .doc();
    final txn = MoneyTransaction(
      id: txnRef.id,
      type: received ? TxnType.income : TxnType.expense,
      amount: amount,
      date: now,
      accountId: accountId,
      categoryId: received
          ? 'cat_salary'
          : 'cat_other', // refined by the UI when possible
      note: note.isEmpty
          ? (received
                ? 'دفعة من دين لي — ${debt.person}'
                : 'دفعة لديون عليّ — ${debt.person}')
          : note,
      source: TxnSource.debt,
    );

    final payment = DebtPayment(amount: amount, date: now, note: note).toMap();

    final batch = _db.batch();
    batch.set(txnRef, txn.toMap());
    batch.update(_col(uid).doc(debt.id), {
      'payments': FieldValue.arrayUnion([payment]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_account(uid, accountId), {
      'balance': FieldValue.increment(received ? amount : -amount),
    });
    await batch.commit();
  }
}
