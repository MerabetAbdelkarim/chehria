// Deletion guards (accounts, categories), the system-category backfill and
// the backup / delete-everything repository, on an in-memory Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/core/constants/app_constants.dart';
import 'package:masarifi/features/accounts/data/account_repository.dart';
import 'package:masarifi/features/auth/data/bootstrap_repository.dart';
import 'package:masarifi/features/categories/data/category_repository.dart';
import 'package:masarifi/features/settings/data/user_data_repository.dart';

const uid = 'u1';

/// Only `uid`, `displayName` and `email` are read by the bootstrap.
class _FakeUser implements User {
  @override
  String get uid => 'u1';
  @override
  String? get displayName => 'Karim';
  @override
  String? get email => 'k@example.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late FakeFirebaseFirestore db;

CollectionReference<Map<String, dynamic>> col(String name) =>
    db.collection('users').doc(uid).collection(name);

void main() {
  setUp(() => db = FakeFirebaseFirestore());

  group('account isInUse', () {
    test('is false for an account without operations', () async {
      await col('accounts').doc('cash').set({'name': 'Cash', 'balance': 0});
      expect(await AccountRepository(db).isInUse(uid, 'cash'), isFalse);
    });

    test('is true once an operation or a transfer uses it', () async {
      await col('transactions').doc('t1').set({'accountId': 'cash'});
      await col('transactions').doc('t2').set({'toAccountId': 'ccp'});
      final repo = AccountRepository(db);
      expect(await repo.isInUse(uid, 'cash'), isTrue);
      expect(await repo.isInUse(uid, 'ccp'), isTrue);
      expect(await repo.isInUse(uid, 'card'), isFalse);
    });
  });

  group('categories', () {
    test('system categories are recognised', () {
      expect(CategoryRepository.isSystem(AppConstants.catOther), isTrue);
      expect(CategoryRepository.isSystem(AppConstants.catDawra), isTrue);
      expect(CategoryRepository.isSystem('cat_food'), isFalse);
    });

    test('isInUse looks at operations, budgets and subscriptions', () async {
      final repo = CategoryRepository(db);
      expect(await repo.isInUse(uid, 'cat_food'), isFalse);

      await col('budgets').doc('b').set({'categoryId': 'cat_food'});
      expect(await repo.isInUse(uid, 'cat_food'), isTrue);

      await col('subscriptions').doc('s').set({'categoryId': 'cat_bills'});
      expect(await repo.isInUse(uid, 'cat_bills'), isTrue);
    });
  });

  group('bootstrap', () {
    test('a new user gets the profile and every seed category', () async {
      await BootstrapRepository(db).ensureProfile(_FakeUser());
      final cats = (await col('categories').get()).docs.map((d) => d.id);
      expect(cats, containsAll(AppConstants.systemCategoryIds));
      expect((await db.collection('users').doc(uid).get()).exists, isTrue);
    });

    test('an existing user gets the new system categories only', () async {
      await db.collection('users').doc(uid).set({'salary': 1});
      await col(
        'categories',
      ).doc(AppConstants.catOther).set({'nameAr': 'مخصص', 'nameFr': 'Perso'});

      await BootstrapRepository(db).ensureProfile(_FakeUser());

      final cats = await col('categories').get();
      final ids = cats.docs.map((d) => d.id).toSet();
      expect(ids, AppConstants.systemCategoryIds);
      // The user's renamed category is left untouched.
      final other = cats.docs.firstWhere((d) => d.id == AppConstants.catOther);
      expect(other.data()['nameAr'], 'مخصص');
    });
  });

  group('user data', () {
    setUp(() async {
      await db.collection('users').doc(uid).set({
        'salary': 45000,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
      });
      await col('accounts').doc('cash').set({'name': 'Cash', 'balance': 10});
      for (var i = 0; i < 3; i++) {
        await col('transactions').doc('t$i').set({
          'amount': 100 + i,
          'date': Timestamp.fromDate(DateTime.utc(2026, 10, i + 1)),
        });
      }
      // Another user's data must never be touched.
      await db.collection('users').doc('other').set({'salary': 1});
      await db
          .collection('users')
          .doc('other')
          .collection('transactions')
          .doc('x')
          .set({'amount': 1});
    });

    test('export contains every collection as plain JSON', () async {
      final data = await UserDataRepository(db).exportAll(uid);
      expect(data['format'], 'masarifi-backup');
      expect(data['profile']['salary'], 45000);
      expect(data['profile']['createdAt'], '2026-01-02T00:00:00.000Z');
      expect(data['accounts'], hasLength(1));
      expect(data['transactions'], hasLength(3));
      expect((data['transactions'] as List).first['date'], isA<String>());
      for (final name in UserDataRepository.collections) {
        expect(data.containsKey(name), isTrue, reason: name);
      }
      expect(await UserDataRepository(db).exportJson(uid), contains('"id"'));
    });

    test('deleteAll removes the user and only that user', () async {
      await UserDataRepository(db).deleteAll(uid);

      expect((await db.collection('users').doc(uid).get()).exists, isFalse);
      for (final name in UserDataRepository.collections) {
        expect((await col(name).get()).docs, isEmpty, reason: name);
      }
      final other = db.collection('users').doc('other');
      expect((await other.get()).exists, isTrue);
      expect((await other.collection('transactions').get()).docs, hasLength(1));
    });
  });
}
