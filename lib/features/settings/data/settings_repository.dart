import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_settings.dart';

/// Reads/writes `users/{uid}` — the profile + settings document.
class SettingsRepository {
  SettingsRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserSettings> watch(String uid) =>
      _doc(uid).snapshots().map(UserSettings.fromDoc);

  Future<UserSettings?> read(String uid) async {
    final doc = await _doc(uid).get();
    if (!doc.exists) return null;
    return UserSettings.fromDoc(doc);
  }

  /// Partial update with merge — never clobbers the whole document.
  Future<void> updateFields(String uid, Map<String, dynamic> fields) =>
      _doc(uid).set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveDisplayName(String uid, String displayName) =>
      updateFields(uid, {'displayName': displayName});

  Future<void> savePayPeriod({
    required String uid,
    required int salary,
    required int payday,
  }) => updateFields(uid, {
    'salary': salary,
    'payday': payday,
    'setupCompleted': true,
  });

  Future<void> saveLocale(String uid, String locale) =>
      updateFields(uid, {'locale': locale});

  Future<void> saveCurrencyDisplay(String uid, String mode) =>
      updateFields(uid, {'currencyDisplay': mode});

  Future<void> saveThemeMode(String uid, String mode) =>
      updateFields(uid, {'themeMode': mode});

  Future<void> saveNotificationsEnabled(String uid, bool enabled) =>
      updateFields(uid, {'notificationsEnabled': enabled});
}
