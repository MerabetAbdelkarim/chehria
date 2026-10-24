import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_data.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../core/localization/s.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/categories_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../transactions/models/money_transaction.dart';
import '../../transactions/presentation/transaction_form_sheet.dart';
import '../../transactions/providers/transactions_providers.dart';
import '../domain/dashboard_calculator.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/before_payday_card.dart';
import 'widgets/goals_card.dart';
import 'widgets/home_alerts.dart';
import 'widgets/period_summary.dart';
import 'widgets/today_card.dart';

/// The dashboard: pay period, money left, charts, debts and recent activity.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) => refreshDashboard(ref);

  Future<void> _recordSalary(
    BuildContext context,
    WidgetRef ref,
    DashboardData data,
  ) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    if (data.salaryRecorded) {
      showAppSnack(context, s.salaryAlreadyRecorded);
      return;
    }
    if (data.salary <= 0) {
      showAppSnack(context, s.monthlySalary, error: true);
      return;
    }

    final accountId = ref.read(defaultAccountProvider)?.id;
    if (accountId == null) {
      showAppSnack(context, s.pickAccount, error: true);
      return;
    }

    final txn = MoneyTransaction(
      id: '',
      type: TxnType.income,
      amount: data.salary,
      date: data.period.start,
      categoryId: AppConstants.catSalary,
      accountId: accountId,
      note: s.recordSalary,
      source: TxnSource.salary,
    );

    try {
      await ref.read(transactionRepositoryProvider).add(uid, txn);
      if (context.mounted) showAppSnack(context, s.salaryRecorded);
    } catch (e, st) {
      reportError(e, st, reason: 'dashboard_screen');
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.appName)),
      body: dashboard.when(
        loading: () => LoadingView(label: s.loading),
        error: (error, stack) =>
            ErrorView(message: s.errorGeneric, onRetry: () => _refresh(ref)),
        data: (data) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            // Order = how often each question is asked: today's money,
            // what must be paid before pay day, what needs attention, then
            // history and analysis.
            children: [
              TodayCard(data: data),
              const SizedBox(height: 12),
              const BeforePaydayCard(),
              const SizedBox(height: 12),
              HomeAlerts(
                data: data,
                onRecordSalary: () => _recordSalary(context, ref, data),
              ),
              const SizedBox(height: 8),
              _RecentSection(onRefresh: () => _refresh(ref)),
              const SizedBox(height: 12),
              PeriodSummarySection(data: data),
              const SizedBox(height: 12),
              const GoalsCard(limit: 1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Last few operations with a link to the full list.
class _RecentSection extends ConsumerWidget {
  const _RecentSection({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final recent = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoriesOrNullProvider);
    final millions = ref.watch(millionsModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.recent,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AsyncValueView(
          value: recent,
          onRetry: onRefresh,
          data: (list) {
            if (list.isEmpty) {
              return EmptyView(
                icon: Icons.receipt_long_outlined,
                title: s.noTransactions,
                subtitle: s.emptySubtitle,
              );
            }
            final top = list.take(5).toList();
            return Column(
              children: [
                for (final txn in top)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => TransactionFormSheet.show(context, txn),
                      leading: CircleAvatar(
                        backgroundColor: _colorFor(
                          txn,
                          categories,
                          theme,
                        ).withValues(alpha: .16),
                        child: Icon(
                          _iconFor(txn, categories),
                          size: 20,
                          color: _colorFor(txn, categories, theme),
                        ),
                      ),
                      title: Text(
                        _titleFor(txn, categories, s),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        formatDateRelative(
                          txn.date,
                          DateTime.now(),
                          isAr: s.isAr,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: AmountText(
                        // Income is positive; expenses and transfers leave the account.
                        txn.isIncome ? txn.amount : -txn.amount,
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
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Color _colorFor(
    MoneyTransaction txn,
    List<Category> categories,
    ThemeData theme,
  ) {
    if (txn.isTransfer) return theme.colorScheme.primary;
    for (final c in categories) {
      if (c.id == txn.categoryId) return Color(c.colorValue);
    }
    return theme.colorScheme.outline;
  }

  IconData _iconFor(MoneyTransaction txn, List<Category> categories) {
    if (txn.isTransfer) return Icons.swap_horiz_rounded;
    for (final c in categories) {
      if (c.id == txn.categoryId) return DefaultData.iconOf(c.iconCode);
    }
    return Icons.help_outline_rounded;
  }

  String _titleFor(MoneyTransaction txn, List<Category> categories, S s) {
    if (txn.isTransfer) return s.transferShort;
    for (final c in categories) {
      if (c.id == txn.categoryId) return c.name(isAr: s.isAr);
    }
    return s.uncategorized;
  }
}
