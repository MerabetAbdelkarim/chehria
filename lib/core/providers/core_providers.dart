import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/data/account_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/bootstrap_repository.dart';
import '../../features/budgets/data/budget_repository.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/dart/data/dart_repository.dart';
import '../../features/debts/data/debt_repository.dart';
import '../../features/goals/data/goal_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/data/user_data_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';

/// Firebase singletons.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Current Firebase auth state.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authStateProvider).valueOrNull,
);

/// The signed-in user's id, or `null`.
final uidProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.uid,
);

/// Repositories (one instance each).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

final bootstrapRepositoryProvider = Provider<BootstrapRepository>(
  (ref) => BootstrapRepository(ref.watch(firestoreProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(firestoreProvider)),
);

final userDataRepositoryProvider = Provider<UserDataRepository>(
  (ref) => UserDataRepository(ref.watch(firestoreProvider)),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(firestoreProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(firestoreProvider)),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(firestoreProvider)),
);

final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) => DebtRepository(ref.watch(firestoreProvider)),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(firestoreProvider)),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(firestoreProvider)),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(ref.watch(firestoreProvider)),
);

final dartRepositoryProvider = Provider<DartRepository>(
  (ref) => DartRepository(ref.watch(firestoreProvider)),
);

/// "Now" — only changed explicitly (pull to refresh / on pay day rollover).
final nowProvider = StateProvider<DateTime>((ref) => DateTime.now());
