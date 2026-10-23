import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_data.dart';

/// Creates the user's root document plus seed accounts/categories on first
/// sign-in. Everything goes through **one batched write**.
class BootstrapRepository {
  BootstrapRepository(this._db);

  final FirebaseFirestore _db;

  Future<void> ensureProfile(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    if (snapshot.exists) return;

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
}
