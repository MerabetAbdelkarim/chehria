import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';

/// Everything stored for one user, as a whole: JSON backup and permanent
/// deletion (required by the stores for apps that create accounts).
class UserDataRepository {
  UserDataRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Every sub-collection under `users/{uid}`.
  static const List<String> collections = [
    AppConstants.colAccounts,
    AppConstants.colCategories,
    AppConstants.colTransactions,
    AppConstants.colSubscriptions,
    AppConstants.colDebts,
    AppConstants.colBudgets,
    AppConstants.colGoals,
    AppConstants.colDart,
  ];

  /// Firestore caps a batch at 500 writes.
  static const int _batchLimit = 450;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  /// A self-describing snapshot of all the user's documents.
  ///
  /// Timestamps become ISO-8601 strings so the file is plain, portable JSON.
  Future<Map<String, dynamic>> exportAll(String uid) async {
    final profile = await _user(uid).get();
    final data = <String, dynamic>{
      'format': 'masarifi-backup',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'profile': _plain(profile.data() ?? const {}),
    };
    for (final name in collections) {
      final snap = await _user(uid).collection(name).get();
      data[name] = [
        for (final doc in snap.docs) {'id': doc.id, ..._plain(doc.data())},
      ];
    }
    return data;
  }

  /// [exportAll] encoded as indented UTF-8 JSON.
  Future<String> exportJson(String uid) async =>
      const JsonEncoder.withIndent('  ').convert(await exportAll(uid));

  /// Permanently deletes every document of the user, sub-collections first
  /// and the profile last, in batches.
  Future<void> deleteAll(String uid) async {
    for (final name in collections) {
      final col = _user(uid).collection(name);
      while (true) {
        final snap = await col.limit(_batchLimit).get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (snap.docs.length < _batchLimit) break;
      }
    }
    await _user(uid).delete();
  }

  static Map<String, dynamic> _plain(Map<String, dynamic> map) => {
    for (final e in map.entries) e.key: _plainValue(e.value),
  };

  static Object? _plainValue(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Map) return _plain(Map<String, dynamic>.from(value));
    if (value is List) return value.map(_plainValue).toList();
    return value;
  }
}
