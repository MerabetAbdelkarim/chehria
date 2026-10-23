import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_data.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/categories_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../domain/budget_status.dart';
import '../models/budget.dart';
import '../providers/budgets_providers.dart';
import 'budget_form_sheet.dart';

/// Monthly spending ceilings per category, with 80 % / 100 % alerts.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const BudgetsScreen());

  void _shiftMonth(WidgetRef ref, int delta) {
    final current = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).state = Budget.addMonths(
      current,
      delta,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BudgetRow row,
  ) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteBudgetConfirm,
    );
    if (!ok || !context.mounted) return;

    try {
      await ref.read(budgetRepositoryProvider).delete(uid, row.budget.id);
      if (context.mounted) showAppSnack(context, s.budgetDeleted);
    } catch (e, st) {
      reportError(e, st, reason: 'budgets_screen');
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final rowsAsync = ref.watch(monthBudgetsProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.budgets)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BudgetFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addBudget),
      ),
      body: Column(
        children: [
          _MonthHeader(month: month, onShift: (d) => _shiftMonth(ref, d)),
          Expanded(
            child: AsyncValueView(
              value: rowsAsync,
              onRetry: () => ref.invalidate(monthBudgetsProvider),
              data: (_) {
                final rows = ref.watch(budgetRowsProvider);
                if (rows.isEmpty) {
                  return EmptyView(
                    icon: Icons.savings_outlined,
                    title: s.noBudgetsYet,
                    subtitle: s.setBudgetLimit,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: rows.length,
                  itemBuilder: (context, i) => _BudgetTile(
                    key: ValueKey(rows[i].budget.id),
                    row: rows[i],
                    onEdit: () =>
                        BudgetFormSheet.show(context, budget: rows[i].budget),
                    onDelete: () => _delete(context, ref, rows[i]),
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

/// Month title with previous / next arrows.
class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.month, required this.onShift});

  final String month;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final nowKey = Budget.monthKeyOf(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: s.previous,
            onPressed: () => onShift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                monthLabelOf(month, isAr: s.isAr),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: s.next,
            onPressed: month == nowKey ? null : () => onShift(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _BudgetTile extends ConsumerWidget {
  const _BudgetTile({
    super.key,
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetRow row;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final categories = ref.watch(categoriesOrNullProvider);

    Category? category;
    for (final c in categories) {
      if (c.id == row.budget.categoryId) category = c;
    }
    final color = category == null
        ? theme.colorScheme.primary
        : Color(category.colorValue);
    final levelColor = switch (row.level) {
      BudgetLevel.exceeded => theme.colorScheme.error,
      BudgetLevel.warning => theme.colorScheme.tertiary,
      BudgetLevel.ok => color,
    };

    return Dismissible(
      key: ValueKey(row.budget.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete();
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
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: .14),
                      child: Icon(
                        category == null
                            ? Icons.category_outlined
                            : DefaultData.iconOf(category.iconCode),
                        size: 19,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category?.name(isAr: s.isAr) ?? s.uncategorized,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (row.level != BudgetLevel.ok)
                      Icon(
                        row.level == BudgetLevel.exceeded
                            ? Icons.error_outline_rounded
                            : Icons.warning_amber_rounded,
                        size: 19,
                        color: levelColor,
                      ),
                    const SizedBox(width: 6),
                    AmountText(
                      row.remaining,
                      millionsMode: millions,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: row.ratio.clamp(0.0, 1.0),
                    minHeight: 8,
                    color: levelColor,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.spent} ${formatAmount(row.spent, millionsMode: millions)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '${s.budgetLimit} ${formatAmount(row.budget.limit, millionsMode: millions)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (row.level == BudgetLevel.warning) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.budgetWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (row.level == BudgetLevel.exceeded) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.budgetExceeded,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `أكتوبر 2026` / `octobre 2026` from a `YYYY-MM` key.
String monthLabelOf(String monthKey, {required bool isAr}) {
  final parts = monthKey.split('-');
  return monthLabel(int.parse(parts[0]), int.parse(parts[1]), isAr: isAr);
}
