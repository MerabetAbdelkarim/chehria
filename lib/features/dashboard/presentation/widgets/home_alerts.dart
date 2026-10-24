import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../budgets/domain/budget_status.dart';
import '../../../budgets/presentation/budgets_screen.dart';
import '../../../categories/providers/categories_providers.dart';
import '../../../debts/presentation/debts_screen.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../domain/dashboard_calculator.dart';
import '../../providers/home_providers.dart';

/// Short, actionable notices shown only when something needs attention:
/// salary not recorded yet, budgets near or over their ceiling, old debts.
class HomeAlerts extends ConsumerWidget {
  const HomeAlerts({
    super.key,
    required this.data,
    required this.onRecordSalary,
  });

  final DashboardData data;
  final Future<void> Function() onRecordSalary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final scheme = Theme.of(context).colorScheme;
    final millions = ref.watch(millionsModeProvider);
    final budgets = ref.watch(budgetAlertsProvider);
    final oldDebts = ref.watch(oldDebtsProvider);
    final categories = ref.watch(categoriesOrNullProvider);

    String categoryName(String id) {
      for (final c in categories) {
        if (c.id == id) return c.name(isAr: s.isAr);
      }
      return s.uncategorized;
    }

    final alerts = <Widget>[
      if (!data.salaryRecorded && data.salary > 0)
        _AlertTile(
          icon: Icons.payments_rounded,
          color: scheme.primary,
          text: s.salaryNotRecorded,
          action:
              '${s.recordSalary} · '
              '${formatAmount(data.salary, millionsMode: millions)}',
          onTap: onRecordSalary,
        ),
      for (final row in budgets.take(3))
        _AlertTile(
          icon: row.level == BudgetLevel.exceeded
              ? Icons.error_outline_rounded
              : Icons.warning_amber_rounded,
          color: row.level == BudgetLevel.exceeded
              ? scheme.error
              : const Color(0xFFC77800),
          text: s.budgetAlert(
            categoryName(row.budget.categoryId),
            formatPercent(row.ratio, isAr: s.isAr),
          ),
          onTap: () => Navigator.of(context).push(BudgetsScreen.route()),
        ),
      for (final debt in oldDebts.take(2))
        _AlertTile(
          icon: Icons.history_rounded,
          color: scheme.tertiary,
          text: s.oldDebtAlert(debt.person),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const DebtsScreen())),
        ),
    ];

    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in alerts) ...[a, const SizedBox(height: 8)],
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (action != null)
                      Text(
                        action!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
