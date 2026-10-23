import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/account.dart';

/// All wallets of the signed-in user.
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<Account>>.value(const []);
  return ref.watch(accountRepositoryProvider).watch(uid);
});

final accountsOrNullProvider = Provider<List<Account>>(
  (ref) => ref.watch(accountsProvider).valueOrNull ?? const [],
);

/// Sum of every account balance.
final totalBalanceProvider = Provider<int>((ref) {
  var total = 0;
  for (final account in ref.watch(accountsOrNullProvider)) {
    total += account.balance;
  }
  return total;
});

/// First account, used as the default when adding a transaction.
final defaultAccountProvider = Provider<Account?>((ref) {
  final accounts = ref.watch(accountsOrNullProvider);
  return accounts.isEmpty ? null : accounts.first;
});

final accountByIdProvider = Provider.family<Account?, String>((ref, id) {
  for (final account in ref.watch(accountsOrNullProvider)) {
    if (account.id == id) return account;
  }
  return null;
});
