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

  /// Balance change implied by a debt created with `addToBalance`:
  /// borrowing adds money to my balance, lending takes mine away.
  static int creationDelta(Debt debt) =>
      debt.type == DebtType.iOwe ? debt.amount : -debt.amount;

  Future<void> create(String uid, Debt debt, {String? balanceAccountId}) async {
    final ref = _col(uid).doc(debt.id.isEmpty ? null : debt.id);
    final moves = debt.addToBalance && balanceAccountId != null;
    final stored = Debt(
      id: ref.id,
      type: debt.type,
      person: debt.person,
      phone: debt.phone,
      amount: debt.amount,
      date: debt.date,
      dueDate: debt.dueDate,
      note: debt.note,
      payments: debt.payments,
      addToBalance: moves,
      balanceAccountId: moves ? balanceAccountId : null,
      createdAt: debt.createdAt,
    );

    final batch = _db.batch();
    batch.set(ref, stored.toMap());
    if (moves) {
      final delta = creationDelta(debt);
      if (delta != 0) {
        batch.update(_account(uid, balanceAccountId), {
          'balance': FieldValue.increment(delta),
        });
      }
    }
    await batch.commit();
  }

  /// Saves the edited fields. `payments` is never rewritten here (it is only
  /// changed atomically by [addPayment]); when the amount of a debt that moved
  /// a wallet changes, the wallet follows.
  Future<void> update(String uid, Debt previous, Debt debt) async {
    final data = debt.toMap()..remove('payments');
    final batch = _db.batch();
    batch.set(_col(uid).doc(debt.id), data, SetOptions(merge: true));

    final accountId = previous.balanceAccountId;
    if (previous.addToBalance && accountId != null) {
      final delta = creationDelta(debt) - creationDelta(previous);
      if (delta != 0) {
        batch.update(_account(uid, accountId), {
          'balance': FieldValue.increment(delta),
        });
      }
    }
    await batch.commit();
  }

  /// Deletes the debt and, when its creation moved a wallet, moves the money
  /// back. Payment operations stay in the ledger: that cash really moved.
  Future<void> delete(String uid, Debt debt) async {
    final batch = _db.batch();
    batch.delete(_col(uid).doc(debt.id));

    final accountId = debt.balanceAccountId;
    if (debt.addToBalance && accountId != null) {
      final delta = -creationDelta(debt);
      if (delta != 0) {
        batch.update(_account(uid, accountId), {
          'balance': FieldValue.increment(delta),
        });
      }
    }
    await batch.commit();
  }

  /// Adds a partial payment:
  /// - `iOwe`      -> an **expense** (I gave money back)
  /// - `owedToMe`  -> an **income**  (I received money)
  ///
  /// One batch: transaction + debt payments array + account balance.
  /// [note] is the localized label written on the ledger operation.
  Future<void> addPayment({
    required String uid,
    required Debt debt,
    required int amount,
    required String accountId,
    required String note,
    DateTime? date,
    String paymentNote = '',
  }) async {
    final now = date ?? DateTime.now();
    final received = debt.type == DebtType.owedToMe;

    final txnRef = _db
        .collection('users')
        .doc(uid)
        .collection(AppConstants.colTransactions)
        .doc();
    // The ledger operation id doubles as the payment id: one per payment.
    final paymentId = txnRef.id;

    final txn = MoneyTransaction(
      id: txnRef.id,
      type: received ? TxnType.income : TxnType.expense,
      amount: amount,
      date: now,
      accountId: accountId,
      categoryId: AppConstants.catDebts,
      note: note,
      source: TxnSource.debt,
      linkedId: debt.id,
      linkedPaymentId: paymentId,
    );

    final payment = DebtPayment(
      id: paymentId,
      amount: amount,
      date: now,
      note: paymentNote,
    ).toMap();

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
