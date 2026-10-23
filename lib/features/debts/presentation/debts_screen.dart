import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/debt.dart';
import '../providers/debts_providers.dart';
import 'debt_form_sheet.dart';
import 'debt_payment_sheet.dart';

/// Both sides of the ledger: what I owe and what is owed to me.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  DebtType? _filter; // null = both

  Future<void> _delete(Debt debt) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteDebtConfirm,
    );
    if (!ok) return;

    try {
      await ref.read(debtRepositoryProvider).delete(uid, debt.id);
      if (mounted) showAppSnack(context, s.debtDeleted);
    } catch (_) {
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final debts = ref.watch(debtsProvider);
    final iOweTotal = ref.watch(iOweTotalProvider);
    final owedToMeTotal = ref.watch(owedToMeTotalProvider);
    final millions = ref.watch(millionsModeProvider);
    final now = ref.watch(nowProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.debts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DebtFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addDebt),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _TotalChip(
                    label: s.owedToMe,
                    amount: owedToMeTotal,
                    color: const Color(0xFF00873D),
                    selected: _filter == DebtType.owedToMe,
                    millions: millions,
                    onTap: () => setState(
                      () => _filter = _filter == DebtType.owedToMe
                          ? null
                          : DebtType.owedToMe,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TotalChip(
                    label: s.iOwe,
                    amount: iOweTotal,
                    color: theme.colorScheme.error,
                    selected: _filter == DebtType.iOwe,
                    millions: millions,
                    onTap: () => setState(
                      () => _filter = _filter == DebtType.iOwe
                          ? null
                          : DebtType.iOwe,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: debts,
              onRetry: () => ref.invalidate(debtsProvider),
              data: (all) {
                final items = _filter == null
                    ? all
                    : all.where((d) => d.type == _filter).toList();
                if (items.isEmpty) {
                  return EmptyView(
                    icon: Icons.handshake_rounded,
                    title: s.noDebtsYet,
                    subtitle: s.emptySubtitle,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _DebtTile(
                    key: ValueKey(items[i].id),
                    debt: items[i],
                    now: now,
                    onDelete: () => _delete(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.selected,
    required this.millions,
    required this.onTap,
  });

  final String label;
  final int amount;
  final Color color;
  final bool selected;
  final bool millions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .16)
              : color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: color, width: 1.4) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            AmountText(
              amount,
              millionsMode: millions,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtTile extends ConsumerWidget {
  const _DebtTile({
    super.key,
    required this.debt,
    required this.now,
    required this.onDelete,
  });

  final Debt debt;
  final DateTime now;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final receivable = debt.type == DebtType.owedToMe;
    final color = receivable
        ? const Color(0xFF00873D)
        : theme.colorScheme.error;
    final settled = debt.isSettled;
    final old = !settled && debt.isOld(now);

    final subtitle = <String>[
      if (debt.payments.isNotEmpty)
        '${s.paidAmount}: ${formatAmount(debt.paidTotal, millionsMode: millions)} / ${formatAmount(debt.amount, millionsMode: millions)}',
      if (debt.dueDate != null)
        '${s.dueDate}: ${formatDateShort(debt.dueDate!)}',
      if (debt.phone != null && debt.phone!.isNotEmpty) debt.phone!,
    ].join(' • ');

    return Dismissible(
      key: ValueKey(debt.id),
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
          onTap: () => DebtFormSheet.show(context, debt: debt),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .16),
            child: Icon(
              receivable
                  ? Icons.call_received_rounded
                  : Icons.call_made_rounded,
              color: color,
              size: 21,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  debt.person,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (settled)
                _Badge(label: s.debtSettled, color: theme.colorScheme.primary)
              else if (old)
                _Badge(label: s.oldDebt, color: color),
            ],
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    debt.remaining,
                    millionsMode: millions,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    settled ? s.debtSettled : s.amountRemaining,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: s.recordPayment,
                onPressed: settled
                    ? null
                    : () => DebtPaymentSheet.show(context, debt),
                icon: Icon(
                  receivable
                      ? Icons.add_card_outlined
                      : Icons.payments_outlined,
                  size: 21,
                  color: settled ? theme.colorScheme.outline : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
