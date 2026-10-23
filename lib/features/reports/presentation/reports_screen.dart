import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_data.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../budgets/models/budget.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../budgets/providers/budgets_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../transactions/models/money_transaction.dart';
import '../data/export_service.dart';
import '../domain/monthly_report.dart';

/// Monthly summary + category breakdown + Excel/PDF export.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen());

  void _shiftMonth(WidgetRef ref, int delta) {
    final current = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).state = Budget.addMonths(
      current,
      delta,
    );
  }

  Future<void> _exportMonthly(
    BuildContext context,
    WidgetRef ref,
    MonthlyReport report,
    List<MoneyTransaction> transactions,
    bool asExcel,
  ) async {
    final s = ref.read(sProvider);
    final accounts = ref.read(accountsOrNullProvider);
    final accountNames = <String, String>{
      for (final a in accounts) a.id: a.name,
    };
    final categories = ref.read(categoriesOrNullProvider);

    try {
      if (asExcel) {
        await ExportService.shareExcel(
          report: report,
          transactions: transactions,
          categories: categories,
          accountNames: accountNames,
          isAr: s.isAr,
        );
      } else {
        await ExportService.sharePdf(
          report: report,
          transactions: transactions,
          categories: categories,
          accountNames: accountNames,
        );
      }
    } catch (_) {
      if (context.mounted) showAppSnack(context, s.exportFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final month = ref.watch(selectedMonthProvider);
    final txnsAsync = ref.watch(monthTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.reports)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: s.previous,
                  onPressed: () => _shiftMonth(ref, -1),
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
                  onPressed: () => _shiftMonth(ref, 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: txnsAsync,
              onRetry: () => ref.invalidate(monthTransactionsProvider),
              data: (transactions) {
                final categories = ref.watch(categoriesOrNullProvider);
                final report = buildMonthlyReport(
                  transactions: transactions,
                  categories: categories,
                  monthKey: month,
                );
                if (report.isEmpty) {
                  return EmptyView(
                    icon: Icons.insights_outlined,
                    title: s.reportEmpty,
                    subtitle: s.emptySubtitle,
                  );
                }
                final millions = ref.watch(millionsModeProvider);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  children: [
                    // --------------------------------------------- summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryColumn(
                                label: s.reportIncome,
                                amount: report.income,
                                millions: millions,
                                color: const Color(0xFF00873D),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 44,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            Expanded(
                              child: _SummaryColumn(
                                label: s.reportExpense,
                                amount: report.expense,
                                millions: millions,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 44,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            Expanded(
                              child: _SummaryColumn(
                                label: s.reportNet,
                                amount: report.net,
                                millions: millions,
                                color: report.net >= 0
                                    ? const Color(0xFF00873D)
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _exportMonthly(
                              context,
                              ref,
                              report,
                              transactions,
                              true,
                            ),
                            icon: const Icon(Icons.table_chart_outlined),
                            label: Text(s.exportExcel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _exportMonthly(
                              context,
                              ref,
                              report,
                              transactions,
                              false,
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(s.exportPdf),
                          ),
                        ),
                      ],
                    ),
                    if (report.byCategory.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        s.reportByCategory,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final row in report.byCategory)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(
                                row.colorValue,
                              ).withValues(alpha: .14),
                              child: Icon(
                                DefaultData.iconOf(row.iconCode),
                                size: 19,
                                color: Color(row.colorValue),
                              ),
                            ),
                            title: Text(
                              row.name.isEmpty ? s.uncategorized : row.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${row.count} ${s.reportOperations}'
                              ' â€¢ ${formatPercent(report.expense == 0 ? 0 : row.total / report.expense, isAr: s.isAr)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: AmountText(
                              row.total,
                              millionsMode: millions,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.amount,
    required this.millions,
    required this.color,
  });

  final String label;
  final int amount;
  final bool millions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AmountText(
          amount,
          millionsMode: millions,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
