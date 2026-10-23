import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/budget.dart';

/// Monthly category ceilings, stored as `users/{uid}/budgets/{month}_{categoryId}`.
class BudgetRepository {
  BudgetRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(AppConstants.colBudgets);

  /// Every budget of one calendar month (`YYYY-MM`).
  Stream<List<Budget>> watchMonth(String uid, String month) => _col(uid)
      .where('month', isEqualTo: month)
      .snapshots()
      .map((s) => s.docs.map(Budget.fromDoc).toList());

  /// Upserts one category ceiling (document id derived from month + category).
  Future<void> save(String uid, Budget budget) {
    final id = '${budget.month}_${budget.categoryId}';
    return _col(uid).doc(id).set(budget.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String uid, String budgetId) =>
      _col(uid).doc(budgetId).delete();
}
