import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/category.dart';

/// User-defined categories.
class CategoryRepository {
  CategoryRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(AppConstants.colCategories);

  Stream<List<Category>> watch(String uid) =>
      _col(uid).snapshots().map((s) => s.docs.map(Category.fromDoc).toList());

  Future<List<Category>> readAll(String uid) async {
    final snapshot = await _col(uid).get();
    return snapshot.docs.map(Category.fromDoc).toList();
  }

  Future<void> create(String uid, Category category) => _col(
    uid,
  ).doc(category.id.isEmpty ? null : category.id).set(category.toMap());

  Future<void> update(String uid, Category category) =>
      _col(uid).doc(category.id).set(category.toMap(), SetOptions(merge: true));

  Future<void> delete(String uid, String categoryId) =>
      _col(uid).doc(categoryId).delete();
}
