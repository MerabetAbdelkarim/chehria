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
  static const Set<String> _acceptedBackupFormats = {
    'chehria-backup',
    'masarifi-backup',
  };

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  /// A self-describing snapshot of all the user's documents.
  ///
  /// Timestamps become ISO-8601 strings so the file is plain, portable JSON.
  Future<Map<String, dynamic>> exportAll(String uid) async {
    final profile = await _user(uid).get();
    final data = <String, dynamic>{
      'format': 'chehria-backup',
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

  /// Replaces the user's data with a validated Chehria or legacy backup.
  Future<void> restoreAll(String uid, Map<String, dynamic> backup) async {
    if (!_acceptedBackupFormats.contains(backup['format'])) {
      throw const FormatException('Unsupported backup format');
    }
    if (backup['version'] != 1) {
      throw const FormatException('Unsupported backup version');
    }

    final rawProfile = backup['profile'];
    if (rawProfile is! Map) {
      throw const FormatException('Backup profile must be an object');
    }
    final profile = _restoreMap(Map<String, dynamic>.from(rawProfile));
    final documents =
        <String, List<MapEntry<String, Map<String, dynamic>>>>{};
    for (final name in collections) {
      final rawDocuments = backup[name];
      if (rawDocuments is! List) {
        throw FormatException('Backup collection "$name" must be an array');
      }

      final ids = <String>{};
      documents[name] = [
        for (final rawDocument in rawDocuments)
          _restoreDocument(rawDocument, name, ids),
      ];
    }

    final writes =
        <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[
          for (final name in collections)
            for (final document in documents[name]!)
              MapEntry(
                _user(uid).collection(name).doc(document.key),
                document.value,
              ),
        ];

    await deleteAll(uid);
    await _user(uid).set(profile);
    for (var start = 0; start < writes.length; start += _batchLimit) {
      final batch = _db.batch();
      final end = start + _batchLimit < writes.length
          ? start + _batchLimit
          : writes.length;
      for (final write in writes.sublist(start, end)) {
        batch.set(write.key, write.value);
      }
      await batch.commit();
    }
  }

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

  static Map<String, dynamic> _restoreMap(Map<String, dynamic> map) => {
    for (final e in map.entries) e.key: _restoreValue(e.key, e.value),
  };

  static MapEntry<String, Map<String, dynamic>> _restoreDocument(
    Object? rawDocument,
    String collection,
    Set<String> ids,
  ) {
    if (rawDocument is! Map) {
      throw FormatException(
        'Backup document in "$collection" must be an object',
      );
    }
    final document = Map<String, dynamic>.from(rawDocument);
    final id = document.remove('id');
    if (id is! String || id.isEmpty || !ids.add(id)) {
      throw FormatException('Backup document in "$collection" has an invalid ID');
    }
    return MapEntry(id, _restoreMap(document));
  }

  static Object? _restoreValue(String key, Object? value) {
    if (value is String &&
        (key == 'date' || key.endsWith('Date') || key.endsWith('At'))) {
      final date = DateTime.tryParse(value);
      if (date == null) {
        throw FormatException('Invalid timestamp in backup field "$key"');
      }
      return Timestamp.fromDate(date.toUtc());
    }
    if (value is Map) return _restoreMap(Map<String, dynamic>.from(value));
    if (value is List) {
      return value.map((item) => _restoreValue(key, item)).toList();
    }
    return value;
  }

  static Object? _plainValue(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Map) return _plain(Map<String, dynamic>.from(value));
    if (value is List) return value.map(_plainValue).toList();
    return value;
  }
}
