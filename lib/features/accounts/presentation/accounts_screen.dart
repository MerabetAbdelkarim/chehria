import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/s.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../models/account.dart';
import '../providers/accounts_providers.dart';
import 'account_form_sheet.dart';
import 'transfer_sheet.dart';

/// Wallets overview: total balance, per-account balance, transfers.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final repo = ref.read(accountRepositoryProvider);
    if (await repo.isInUse(uid, account.id)) {
      if (context.mounted) showAppSnack(context, s.accountInUse, error: true);
      return;
    }

    if (!context.mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteAccountConfirm,
    );
    if (!ok || !context.mounted) return;

    try {
      await repo.delete(uid, account.id);
      if (context.mounted) showAppSnack(context, s.deletedDone);
    } catch (_) {
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider);
    final total = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.accounts),
        actions: [
          IconButton(
            tooltip: s.transfer,
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => TransferSheet.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AccountFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addAccount),
      ),
      body: AsyncValueView(
        value: accounts,
        onRetry: () => ref.invalidate(accountsProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.account_balance_wallet_outlined,
              title: s.noAccounts,
              subtitle: s.emptySubtitle,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.totalBalance,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AmountText(
                        total,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (final account in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(account.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _delete(context, ref, account);
                      return false;
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsetsDirectional.only(end: 22),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    child: Card(
                      child: ListTile(
                        onTap: () =>
                            AccountFormSheet.show(context, account: account),
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            account.colorValue,
                          ).withValues(alpha: .16),
                          child: Icon(
                            _iconFor(account.type),
                            color: Color(account.colorValue),
                          ),
                        ),
                        title: Text(
                          account.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(_typeLabel(account.type, s)),
                        trailing: AmountText(
                          account.balance,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: account.balance < 0
                                ? theme.colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconFor(AccountType type) => switch (type) {
    AccountType.cash => Icons.payments_outlined,
    AccountType.ccp => Icons.account_balance_outlined,
    AccountType.card => Icons.credit_card_outlined,
    AccountType.other => Icons.wallet_outlined,
  };

  String _typeLabel(AccountType type, S s) => switch (type) {
    AccountType.cash => s.cash,
    AccountType.ccp => s.ccp,
    AccountType.card => s.bankCard,
    AccountType.other => s.other,
  };
}
