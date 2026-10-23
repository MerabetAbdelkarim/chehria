import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_data.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/models/account.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/categories_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/money_transaction.dart';
import '../providers/transactions_providers.dart';
import 'transaction_form_sheet.dart';

/// History of operations with filtering, swipe-to-delete and tap-to-edit.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TxnType? _filter; // null = all

  Future<void> _delete(MoneyTransaction txn) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteTransactionConfirm,
    );
    if (!confirmed) return;

    try {
      await ref.read(transactionRepositoryProvider).delete(uid, txn);
      if (mounted) showAppSnack(context, s.transactionDeleted);
    } catch (_) {
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final txns = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.transactions)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: s.all,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: s.expense,
                  selected: _filter == TxnType.expense,
                  onTap: () => setState(() => _filter = TxnType.expense),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: s.incomeShort,
                  selected: _filter == TxnType.income,
                  onTap: () => setState(() => _filter = TxnType.income),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: txns,
              onRetry: () => ref.invalidate(recentTransactionsProvider),
              data: (all) {
                final items = _filter == null
                    ? all
                    : all.where((t) => t.type == _filter).toList();

                if (items.isEmpty) {
                  return EmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: s.noTransactions,
                    subtitle: s.emptySubtitle,
                  );
                }

                final groups = <String, List<MoneyTransaction>>{};
                final order = <String>[];
                for (final t in items) {
                  final key = formatDateShort(t.date);
                  if (!groups.containsKey(key)) {
                    groups[key] = [];
                    order.add(key);
                  }
                  groups[key]!.add(t);
                }

                final now = DateTime.now();
                final children = <Widget>[];
                for (final key in order) {
                  final list = groups[key]!;
                  children.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          Text(
                            formatDateRelative(
                              list.first.date,
                              now,
                              isAr: s.isAr,
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  for (final txn in list) {
                    children.add(
                      _DismissibleTile(
                        key: ValueKey(txn.id),
                        txn: txn,
                        onDelete: () => _delete(txn),
                        onTap: () => TransactionFormSheet.show(context, txn),
                      ),
                    );
                  }
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: children,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DismissibleTile extends ConsumerWidget {
  const _DismissibleTile({
    super.key,
    required this.txn,
    required this.onDelete,
    required this.onTap,
  });

  final MoneyTransaction txn;
  final Future<void> Function() onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesOrNullProvider);
    final accounts = ref.watch(accountsOrNullProvider);
    final millions = ref.watch(millionsModeProvider);

    Category? category;
    for (final c in categories) {
      if (c.id == txn.categoryId) category = c;
    }

    Account? account;
    for (final a in accounts) {
      if (a.id == txn.accountId || a.id == txn.toAccountId) account = a;
    }

    final color = category == null
        ? theme.colorScheme.outline
        : Color(category.colorValue);

    return Dismissible(
      key: ValueKey(txn.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete();
        // The list comes from Firestore: the row disappears as soon as the
        // stream emits, which avoids "dismissed but still in the tree".
        return false;
      },
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 22),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .16),
            child: Icon(
              category == null
                  ? Icons.help_outline_rounded
                  : DefaultData.iconOf(category.iconCode),
              color: color,
              size: 21,
            ),
          ),
          title: Text(
            category?.name(isAr: s.isAr) ?? s.uncategorized,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (account != null) account.name,
              if (txn.note.isNotEmpty) txn.note,
            ].join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                txn.isTransfer ? -txn.amount : txn.amount,
                sign: true,
                colorBySign: !txn.isTransfer,
                millionsMode: millions,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: txn.isTransfer
                      ? theme.colorScheme.onSurfaceVariant
                      : (txn.isIncome
                            ? const Color(0xFF00873D)
                            : theme.colorScheme.error),
                ),
              ),
              Text(
                txn.isTransfer ? s.transferShort : '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
