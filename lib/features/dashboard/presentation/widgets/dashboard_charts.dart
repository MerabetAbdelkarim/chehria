import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../categories/providers/categories_providers.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../domain/dashboard_calculator.dart';

/// Income vs expenses of the current period (+ salary breakdown).
class IncomeExpenseCard extends ConsumerWidget {
  const IncomeExpenseCard({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final ratio = data.income > 0 ? data.expenses / data.income : 0.0;
    final overBudget = ratio > 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: s.income,
                    amount: data.income,
                    color: const Color(0xFF00873D),
                    icon: Icons.arrow_downward_rounded,
                    millions: millions,
                  ),
                ),
                Container(
                  width: 1,
                  height: 54,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _StatColumn(
                    label: s.expenses,
                    amount: data.expenses,
                    color: theme.colorScheme.error,
                    icon: Icons.arrow_upward_rounded,
                    millions: millions,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (data.income > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0, 1),
                  minHeight: 8,
                  color: overBudget
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${s.expenses} ${formatPercent(ratio, isAr: s.isAr)} ${s.of} ${s.income}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Divider(height: 22),
            _MiniRow(
              label: s.monthlySalary,
              amount: data.salary,
              millions: millions,
            ),
            const SizedBox(height: 8),
            _MiniRow(
              label: s.extraIncome,
              amount: data.extraIncome,
              millions: millions,
            ),
            if (data.goalsSetAside != 0) ...[
              const SizedBox(height: 8),
              _MiniRow(
                label: s.setAsideInGoals,
                amount: -data.goalsSetAside,
                millions: millions,
              ),
            ],
            if (data.dawraNet != 0) ...[
              const SizedBox(height: 8),
              _MiniRow(
                label: s.dawraNet,
                amount: data.dawraNet,
                millions: millions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.millions,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  final bool millions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AmountText(
          amount,
          millionsMode: millions,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.label,
    required this.amount,
    required this.millions,
  });

  final String label;
  final int amount;
  final bool millions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        AmountText(amount, millionsMode: millions),
      ],
    );
  }
}

/// Spending by category (pie chart + legend).
class CategoryPieCard extends ConsumerWidget {
  const CategoryPieCard({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesOrNullProvider);

    if (data.expenses <= 0) {
      return const SizedBox.shrink();
    }

    final entries =
        data.expensesByCategory.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    String labelFor(String id) {
      if (id.isEmpty) return s.uncategorized;
      for (final c in categories) {
        if (c.id == id) return c.name(isAr: s.isAr);
      }
      return s.uncategorized;
    }

    Color colorFor(String id) {
      for (final c in categories) {
        if (c.id == id) return Color(c.colorValue);
      }
      return theme.colorScheme.outline;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.spendingByCategory,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          for (final entry in entries)
                            PieChartSectionData(
                              value: entry.value.toDouble(),
                              color: colorFor(entry.key),
                              radius: 52,
                              title: formatPercent(
                                entry.value / data.expenses,
                                isAr: s.isAr,
                              ),
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final entry in entries.take(6)) ...[
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colorFor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  labelFor(entry.key),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatPercent(
                                  entry.value / data.expenses,
                                  isAr: s.isAr,
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// This period vs the previous period (expenses).
class ComparisonCard extends ConsumerWidget {
  const ComparisonCard({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);

    final previous = data.previousExpenses;
    final diff = data.expenses - previous;
    final ratio = previous > 0 ? diff / previous : 0.0;
    final up = diff > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.comparison,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.thisPeriod,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AmountText(data.expenses, millionsMode: millions),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        s.lastPeriod,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AmountText(previous, millionsMode: millions),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: previous == 0
                    ? theme.colorScheme.surfaceContainerHighest
                    : (up
                          ? theme.colorScheme.errorContainer
                          : const Color(0xFF00873D).withValues(alpha: .14)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (previous > 0)
                    Icon(
                      up
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 17,
                      color: up
                          ? theme.colorScheme.error
                          : const Color(0xFF00873D),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      previous == 0
                          ? s.sameAsLast
                          : '${up ? s.expensesUp : s.expensesDown} '
                                '${formatPercent(ratio.abs(), isAr: s.isAr)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: previous == 0
                            ? theme.colorScheme.onSurfaceVariant
                            : (up
                                  ? theme.colorScheme.error
                                  : const Color(0xFF00873D)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
