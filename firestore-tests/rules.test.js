// Security-rules tests, run against the Firestore emulator:
//   firebase emulators:exec --only firestore --project demo-masarifi \
//     "npm --prefix firestore-tests test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  increment,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let env;
const now = Timestamp.now();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-masarifi',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const anon = () => env.unauthenticatedContext().firestore();

const txn = (extra = {}) => ({
  type: 'expense',
  amount: 1500,
  date: now,
  source: 'manual',
  note: '',
  categoryId: 'cat_food',
  accountId: 'acc_cash',
  ...extra,
});

describe('ownership', () => {
  test('a user reads and writes their own data', async () => {
    const db = alice();
    await assertSucceeds(setDoc(doc(db, 'users/alice'), { salary: 45000, payday: 25 }));
    await assertSucceeds(getDoc(doc(db, 'users/alice')));
    await assertSucceeds(setDoc(doc(db, 'users/alice/transactions/t1'), txn()));
  });

  test('another user cannot read or write it', async () => {
    await assertFails(getDoc(doc(bob(), 'users/alice')));
    await assertFails(setDoc(doc(bob(), 'users/alice/transactions/t1'), txn()));
  });

  test('signed-out requests are denied', async () => {
    await assertFails(getDoc(doc(anon(), 'users/alice')));
  });

  test('unknown top-level collections are denied', async () => {
    await assertFails(setDoc(doc(alice(), 'other/x'), { a: 1 }));
  });

  test('the owner can delete everything (account deletion)', async () => {
    const db = alice();
    await setDoc(doc(db, 'users/alice'), { salary: 1 });
    await setDoc(doc(db, 'users/alice/transactions/t1'), txn());
    await assertSucceeds(deleteDoc(doc(db, 'users/alice/transactions/t1')));
    await assertSucceeds(deleteDoc(doc(db, 'users/alice')));
  });
});

describe('profile validation', () => {
  test('rejects an invalid pay day, locale or negative salary', async () => {
    const db = alice();
    await assertFails(setDoc(doc(db, 'users/alice'), { payday: 32 }));
    await assertFails(setDoc(doc(db, 'users/alice'), { locale: 'en' }));
    await assertFails(setDoc(doc(db, 'users/alice'), { salary: -5 }));
    await assertFails(setDoc(doc(db, 'users/alice'), { salary: 100.5 }));
  });
});

describe('transactions validation', () => {
  test('rejects zero, negative or decimal amounts', async () => {
    const db = alice();
    await assertFails(setDoc(doc(db, 'users/alice/transactions/t'), txn({ amount: 0 })));
    await assertFails(setDoc(doc(db, 'users/alice/transactions/t'), txn({ amount: -10 })));
    await assertFails(setDoc(doc(db, 'users/alice/transactions/t'), txn({ amount: 12.5 })));
    await assertFails(setDoc(doc(db, 'users/alice/transactions/t'), txn({ amount: 1e12 })));
  });

  test('rejects an unknown type or source', async () => {
    const db = alice();
    await assertFails(setDoc(doc(db, 'users/alice/transactions/t'), txn({ type: 'gift' })));
    await assertFails(setDoc(doc(db, 'users/alice/transactions/t'), txn({ source: 'x' })));
  });

  test('accepts linked operations from debts, subscriptions and dawras', async () => {
    const db = alice();
    await assertSucceeds(setDoc(doc(db, 'users/alice/transactions/d'),
      txn({ source: 'debt', linkedId: 'debt1', linkedPaymentId: 'd' })));
    await assertSucceeds(setDoc(doc(db, 'users/alice/transactions/s'),
      txn({ source: 'subscription', linkedId: 'sub1', previousDueDate: now })));
    await assertSucceeds(setDoc(doc(db, 'users/alice/transactions/w'),
      txn({ source: 'dawra', linkedId: 'g1', linkedRound: 2 })));
  });
});

describe('accounts', () => {
  test('balance moves with increment, including below zero', async () => {
    const db = alice();
    const ref = doc(db, 'users/alice/accounts/acc_cash');
    await assertSucceeds(setDoc(ref, { name: 'نقد', type: 'cash', balance: 0, colorValue: 1 }));
    await assertSucceeds(updateDoc(ref, { balance: increment(-2500) }));
    await assertFails(updateDoc(ref, { balance: 10.5 }));
  });

  test('legacy documents without optional fields stay editable', async () => {
    const db = alice();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice/accounts/old'), { name: 'Old' });
    });
    await assertSucceeds(updateDoc(doc(db, 'users/alice/accounts/old'), { name: 'Renamed' }));
  });
});

describe('other collections', () => {
  test('debts need a person, a type and a positive amount', async () => {
    const db = alice();
    const ok = { type: 'iOwe', person: 'Ali', amount: 5000, date: now, payments: [] };
    await assertSucceeds(setDoc(doc(db, 'users/alice/debts/d1'), ok));
    await assertFails(setDoc(doc(db, 'users/alice/debts/d2'), { ...ok, person: '' }));
    await assertFails(setDoc(doc(db, 'users/alice/debts/d3'), { ...ok, type: 'maybe' }));
  });

  test('budgets need a YYYY-MM month', async () => {
    const db = alice();
    const ok = { month: '2026-10', categoryId: 'cat_food', limit: 10000 };
    await assertSucceeds(setDoc(doc(db, 'users/alice/budgets/2026-10_cat_food'), ok));
    await assertFails(setDoc(doc(db, 'users/alice/budgets/x'), { ...ok, month: 'oct' }));
  });

  test('goals cannot go below zero', async () => {
    const db = alice();
    const ref = doc(db, 'users/alice/goals/g1');
    await assertSucceeds(setDoc(ref, { name: 'Hajj', targetAmount: 0, savedAmount: 100, entries: [] }));
    await assertFails(updateDoc(ref, { savedAmount: increment(-200) }));
  });

  test('a dawra has at least two members and a round >= 1', async () => {
    const db = alice();
    const ok = { name: 'D', contributionAmount: 10000, memberNames: ['a', 'b'], currentRound: 1 };
    await assertSucceeds(setDoc(doc(db, 'users/alice/dart/g1'), ok));
    await assertFails(setDoc(doc(db, 'users/alice/dart/g2'), { ...ok, memberNames: ['a'] }));
    await assertFails(setDoc(doc(db, 'users/alice/dart/g3'), { ...ok, currentRound: 0 }));
  });

  test('unknown subcollections are denied', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice/secrets/x'), { a: 1 }));
  });
});
