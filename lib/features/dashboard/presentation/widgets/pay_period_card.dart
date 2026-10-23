import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../domain/dashboard_calculator.dart';

/// The headline card: remaining until payday, days left, daily allowance.
class PayPeriodCard extends ConsumerWidget {
  const PayPeriodCard({
    super.key,
    required this.data,
    required this.onRecordSalary,
  });

  final DashboardData data;
  final Future<void> Function() onRecordSalary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final negative = data.isNegative;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: negative
                ? [
                    theme.colorScheme.errorContainer,
                    theme.colorScheme.errorContainer.withValues(alpha: .55),
                  ]
                : [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primaryContainer.withValues(alpha: .55),
                  ],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 18,
                  color: negative
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${s.period}: ${formatRange(data.period.start, data.period.end)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: negative
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.daysLeft <= 1
                        ? s.dayLeft
                        : '${data.daysLeft} ${s.daysLeft}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              s.remaining,
              style: theme.textTheme.labelLarge?.copyWith(
                color: negative
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            AmountText(
              data.remaining,
              millionsMode: millions,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: negative
                    ? theme.colorScheme.error
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (negative) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.negativeWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Divider(
              color:
                  (negative
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer)
                      .withValues(alpha: .2),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.dailyAllowance,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: negative
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AmountText(
                        data.dailyAllowance.round(),
                        millionsMode: millions,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: negative
                              ? theme.colorScheme.error
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: onRecordSalary,
                  icon: Icon(
                    data.salaryRecorded
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    size: 18,
                  ),
                  label: Text(
                    data.salaryRecorded
                        ? s.recordSalary
                        : '${s.recordSalary} • ${formatAmount(data.salary, millionsMode: millions)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
