import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../reports/presentation/reports_screen.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../domain/dashboard_calculator.dart';
import 'dashboard_charts.dart';

/// Analysis of the pay period (income vs expenses, categories, comparison
/// with the previous period), folded by default: it is read weekly, not every
/// time the app is opened.
class PeriodSummarySection extends ConsumerWidget {
  const PeriodSummarySection({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);

    // The analysis cards keep their own layout; flatten them inside the fold.
    final flatCards = theme.copyWith(
      cardTheme: theme.cardTheme.copyWith(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainerLow,
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.insights_rounded,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            s.periodSummary,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${s.income} ${formatAmount(data.income, millionsMode: millions)}'
            ' · '
            '${s.expenses} ${formatAmount(data.expenses, millionsMode: millions)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          children: [
            Theme(
              data: flatCards,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IncomeExpenseCard(data: data),
                  const SizedBox(height: 10),
                  CategoryPieCard(data: data),
                  if (data.expenses > 0) const SizedBox(height: 10),
                  ComparisonCard(data: data),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(ReportsScreen.route()),
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text(s.openReports),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
