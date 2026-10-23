import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_data.dart';

/// Creates the user's root document plus seed accounts/categories on first
/// sign-in. Everything goes through **one batched write**.
///
/// For existing users it back-fills the system categories added by later
/// versions (debts, dawra) without touching the ones they already have.
class BootstrapRepository {
  BootstrapRepository(this._db);

  final FirebaseFirestore _db;

  Future<void> ensureProfile(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    if (snapshot.exists) {
      await _backfillSystemCategories(userDoc);
      return;
    }

    final batch = _db.batch();
    batch.set(userDoc, {
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'salary': 0,
      'payday': 1,
      'locale': 'ar',
      'currencyDisplay': 'dzd',
      'themeMode': 'system',
      'setupCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final account in DefaultData.accounts) {
      batch.set(
        userDoc.collection(AppConstants.colAccounts).doc(account.id),
        account.toMap(),
      );
    }

    for (final category in DefaultData.categories) {
      batch.set(
        userDoc.collection(AppConstants.colCategories).doc(category.id),
        category.toMap(),
      );
    }

    await batch.commit();
  }

  Future<void> _backfillSystemCategories(
    DocumentReference<Map<String, dynamic>> userDoc,
  ) async {
    final col = userDoc.collection(AppConstants.colCategories);
    final existing = (await col.get()).docs.map((d) => d.id).toSet();
    final missing = DefaultData.categories.where(
      (c) =>
          AppConstants.systemCategoryIds.contains(c.id) &&
          !existing.contains(c.id),
    );
    if (missing.isEmpty) return;

    final batch = _db.batch();
    for (final category in missing) {
      batch.set(col.doc(category.id), category.toMap());
    }
    await batch.commit();
  }
}
