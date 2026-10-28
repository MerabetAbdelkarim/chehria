// Repository tests on an in-memory Firestore: every action that moves money
// keeps the ledger, the wallets and the linked document consistent, and
// deleting the operation undoes all of it.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/features/dart/data/dart_repository.dart';
import 'package:chehria/features/dart/models/dart_group.dart';
import 'package:chehria/features/debts/data/debt_repository.dart';
import 'package:chehria/features/debts/models/debt.dart';
import 'package:chehria/features/subscriptions/data/subscription_repository.dart';
import 'package:chehria/features/subscriptions/domain/subscription_calculator.dart';
import 'package:chehria/features/subscriptions/models/subscription.dart';
import 'package:chehria/features/transactions/data/transaction_repository.dart';
import 'package:chehria/features/transactions/models/money_transaction.dart';

const uid = 'u1';

late FakeFirebaseFirestore db;
late TransactionRepository txns;

DocumentReference<Map<String, dynamic>> userDoc(String col, String id) =>
    db.collection('users').doc(uid).collection(col).doc(id);

Future<int> balanceOf(String accountId) async =>
    ((await userDoc('accounts', accountId).get()).data()!['balance'] as num)
        .toInt();

Future<List<MoneyTransaction>> allTxns() async {
  final snap = await db
      .collection('users')
      .doc(uid)
      .collection('transactions')
      .get();
  return snap.docs.map(MoneyTransaction.fromDoc).toList();
}

void main() {
  setUp(() async {
    db = FakeFirebaseFirestore();
    txns = TransactionRepository(db);
    await userDoc('accounts', 'cash').set({'name': 'Cash', 'balance': 10000});
    await userDoc('accounts', 'ccp').set({'name': 'CCP', 'balance': 0});
  });

  group('plain operations', () {
    test('add then delete restores the balance', () async {
      final id = await txns.add(
        uid,
        MoneyTransaction(
          id: '',
          type: TxnType.expense,
          amount: 2500,
          date: DateTime(2026, 10, 5),
          accountId: 'cash',
        ),
      );
      expect(await balanceOf('cash'), 7500);

      final saved = (await allTxns()).single;
      expect(saved.id, id);
      await txns.delete(uid, saved);
      expect(await balanceOf('cash'), 10000);
      expect(await allTxns(), isEmpty);
    });

    test('update moves the difference and the account', () async {
      await txns.add(
        uid,
        MoneyTransaction(
          id: '',
          type: TxnType.expense,
          amount: 1000,
          date: DateTime(2026, 10, 5),
          accountId: 'cash',
        ),
      );
      final saved = (await allTxns()).single;
      await txns.update(uid, saved.copyWith(amount: 1500, accountId: 'ccp'));

      expect(await balanceOf('cash'), 10000);
      expect(await balanceOf('ccp'), -1500);
    });
  });

  group('debts', () {
    late DebtRepository debts;
    setUp(() => debts = DebtRepository(db));

    Future<Debt> createDebt({bool addToBalance = false}) async {
      await debts.create(
        uid,
        Debt(
          id: 'd1',
          type: DebtType.iOwe,
          person: 'Ali',
          amount: 6000,
          date: DateTime(2026, 9, 1),
          addToBalance: addToBalance,
        ),
        balanceAccountId: addToBalance ? 'cash' : null,
      );
      return Debt.fromDoc(await userDoc('debts', 'd1').get());
    }

    test('deleting a payment operation removes the payment too', () async {
      final debt = await createDebt();
      await debts.addPayment(
        uid: uid,
        debt: debt,
        amount: 2000,
        accountId: 'cash',
        note: 'payment',
      );

      var stored = Debt.fromDoc(await userDoc('debts', 'd1').get());
      expect(stored.remaining, 4000);
      expect(await balanceOf('cash'), 8000);

      final payment = (await allTxns()).single;
      expect(payment.source, TxnSource.debt);
      expect(payment.linkedId, 'd1');
      expect(payment.categoryId, 'cat_debts');

      await txns.delete(uid, payment);
      stored = Debt.fromDoc(await userDoc('debts', 'd1').get());
      expect(stored.payments, isEmpty);
      expect(stored.remaining, 6000);
      expect(await balanceOf('cash'), 10000);
    });

    test('only the matching payment is removed', () async {
      final debt = await createDebt();
      for (final amount in [1000, 1500]) {
        await debts.addPayment(
          uid: uid,
          debt: debt,
          amount: amount,
          accountId: 'cash',
          note: '',
        );
      }
      final first = (await allTxns()).firstWhere((t) => t.amount == 1000);
      await txns.delete(uid, first);

      final stored = Debt.fromDoc(await userDoc('debts', 'd1').get());
      expect(stored.payments.map((p) => p.amount), [1500]);
    });

    test('a payment of a deleted debt can still be deleted', () async {
      final debt = await createDebt();
      await debts.addPayment(
        uid: uid,
        debt: debt,
        amount: 1000,
        accountId: 'cash',
        note: '',
      );
      await debts.delete(uid, debt);

      await txns.delete(uid, (await allTxns()).single);
      expect(await balanceOf('cash'), 10000);
    });

    test('addToBalance is reverted when the debt is deleted', () async {
      final debt = await createDebt(addToBalance: true);
      expect(await balanceOf('cash'), 16000); // borrowed money arrived
      expect(debt.balanceAccountId, 'cash');

      await debts.delete(uid, debt);
      expect(await balanceOf('cash'), 10000);
    });

    test(
      'editing the amount of an addToBalance debt moves the wallet',
      () async {
        final debt = await createDebt(addToBalance: true);
        final edited = Debt(
          id: debt.id,
          type: debt.type,
          person: debt.person,
          amount: 9000,
          date: debt.date,
          addToBalance: true,
          balanceAccountId: 'cash',
        );
        await debts.update(uid, debt, edited);
        expect(await balanceOf('cash'), 19000);
      },
    );

    test('editing a debt never overwrites its payments', () async {
      final debt = await createDebt();
      await debts.addPayment(
        uid: uid,
        debt: debt,
        amount: 1000,
        accountId: 'cash',
        note: '',
      );
      // `debt` is the stale copy without the payment.
      await debts.update(uid, debt, debt);
      final stored = Debt.fromDoc(await userDoc('debts', 'd1').get());
      expect(stored.payments, hasLength(1));
    });
  });

  group('subscriptions', () {
    late SubscriptionRepository subs;
    setUp(() => subs = SubscriptionRepository(db));

    Future<Subscription> createSub(DateTime due) async {
      await subs.create(
        uid,
        Subscription(
          id: 's1',
          name: 'Internet',
          amount: 2500,
          cycle: SubscriptionCycle.monthly,
          nextDueDate: due,
        ),
      );
      return Subscription.fromDoc(await userDoc('subscriptions', 's1').get());
    }

    test('paying early still moves the due date one cycle', () async {
      final sub = await createSub(DateTime(2026, 10, 25));
      await subs.recordPayment(
        uid: uid,
        sub: sub,
        accountId: 'cash',
        date: DateTime(2026, 10, 20, 14),
      );
      final stored = Subscription.fromDoc(
        await userDoc('subscriptions', 's1').get(),
      );
      expect(stored.nextDueDate, DateTime(2026, 11, 25));
    });

    test('deleting the payment rewinds the due date', () async {
      final sub = await createSub(DateTime(2026, 10, 25));
      await subs.recordPayment(
        uid: uid,
        sub: sub,
        accountId: 'cash',
        date: DateTime(2026, 10, 25, 9),
      );
      final payment = (await allTxns()).single;
      expect(payment.previousDueDate, DateTime(2026, 10, 25));

      await txns.delete(uid, payment);
      final stored = Subscription.fromDoc(
        await userDoc('subscriptions', 's1').get(),
      );
      expect(stored.nextDueDate, DateTime(2026, 10, 25));
      expect(await balanceOf('cash'), 10000);
    });

    test('an older payment does not rewind a bill paid again since', () async {
      var sub = await createSub(DateTime(2026, 10, 25));
      await subs.recordPayment(
        uid: uid,
        sub: sub,
        accountId: 'cash',
        date: DateTime(2026, 10, 25, 9),
      );
      sub = Subscription.fromDoc(await userDoc('subscriptions', 's1').get());
      await subs.recordPayment(
        uid: uid,
        sub: sub,
        accountId: 'cash',
        date: DateTime(2026, 11, 25, 9),
      );

      final october = (await allTxns()).firstWhere((t) => t.date.month == 10);
      await txns.delete(uid, october);
      final stored = Subscription.fromDoc(
        await userDoc('subscriptions', 's1').get(),
      );
      expect(stored.nextDueDate, DateTime(2026, 12, 25));
    });
  });

  group('dawra', () {
    late DartRepository dawras;
    setUp(() => dawras = DartRepository(db));

    Future<DartGroup> createGroup() async {
      await dawras.create(
        uid,
        DartGroup(
          id: 'g1',
          name: 'Family',
          contributionAmount: 5000,
          memberNames: const ['Me', 'Ali', 'Sara'],
          meName: 'Me',
          currentRound: 1,
          startDate: DateTime(2026, 9, 1),
        ),
      );
      return DartGroup.fromDoc(await userDoc('dart', 'g1').get());
    }

    test('operations use the dawra source and category', () async {
      final group = await createGroup();
      await dawras.payContribution(
        uid: uid,
        group: group,
        memberName: 'Me',
        accountId: 'cash',
        note: 'n',
      );
      final txn = (await allTxns()).single;
      expect(txn.source, TxnSource.dawra);
      expect(txn.categoryId, 'cat_dawra');
    });

    test('deleting a contribution removes its payment entry', () async {
      final group = await createGroup();
      await dawras.payContribution(
        uid: uid,
        group: group,
        memberName: 'Me',
        accountId: 'cash',
        note: 'n',
      );
      expect(
        DartGroup.fromDoc(await userDoc('dart', 'g1').get()).payments,
        hasLength(1),
      );

      await txns.delete(uid, (await allTxns()).single);
      final stored = DartGroup.fromDoc(await userDoc('dart', 'g1').get());
      expect(stored.payments, isEmpty);
      expect(await balanceOf('cash'), 10000);
    });

    test('deleting the latest pot steps the round back', () async {
      final group = await createGroup();
      await dawras.receiveRound(
        uid: uid,
        group: group,
        accountId: 'cash',
        receiverName: 'Me',
        toMe: true,
        note: 'n',
      );
      expect(
        DartGroup.fromDoc(await userDoc('dart', 'g1').get()).currentRound,
        2,
      );
      expect(await balanceOf('cash'), 25000);

      await txns.delete(uid, (await allTxns()).single);
      final stored = DartGroup.fromDoc(await userDoc('dart', 'g1').get());
      expect(stored.currentRound, 1);
      expect(await balanceOf('cash'), 10000);
    });
  });

  test('editing a linked operation keeps its amount and type', () async {
    final debts = DebtRepository(db);
    await debts.create(
      uid,
      Debt(
        id: 'd1',
        type: DebtType.owedToMe,
        person: 'Ali',
        amount: 3000,
        date: DateTime(2026, 9, 1),
      ),
    );
    final debt = Debt.fromDoc(await userDoc('debts', 'd1').get());
    await debts.addPayment(
      uid: uid,
      debt: debt,
      amount: 3000,
      accountId: 'cash',
      note: '',
    );
    final payment = (await allTxns()).single;

    await txns.update(
      uid,
      payment.copyWith(amount: 99, type: TxnType.expense, note: 'edited'),
    );
    final stored = (await allTxns()).single;
    expect(stored.amount, 3000);
    expect(stored.type, TxnType.income);
    expect(stored.note, 'edited');
    expect(await balanceOf('cash'), 13000);
  });

  test('dueAfterPayment advances at least one cycle', () {
    expect(
      dueAfterPayment(
        DateTime(2026, 10, 25),
        SubscriptionCycle.monthly,
        DateTime(2026, 10, 1),
      ),
      DateTime(2026, 11, 25),
    );
    // Overdue by several cycles: the first occurrence not before the payment.
    expect(
      dueAfterPayment(
        DateTime(2026, 7, 25),
        SubscriptionCycle.monthly,
        DateTime(2026, 10, 1),
      ),
      DateTime(2026, 10, 25),
    );
  });
}
