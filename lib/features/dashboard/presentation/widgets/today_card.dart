import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../domain/dashboard_calculator.dart';

/// The headline of the home page: how much can still be spent today, how much
/// of today's budget is gone, and what is left until pay day.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final millions = ref.watch(millionsModeProvider);

    final negative = data.isNegative;
    final overspent = !negative && data.leftToday < 0;
    final onCard = negative
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;
    final muted = onCard.withValues(alpha: .75);

    String amount(int value) => formatAmount(value, millionsMode: millions);

    final ratio = data.todayBudget <= 0
        ? (data.spentToday > 0 ? 1.0 : 0.0)
        : (data.spentToday / data.todayBudget).clamp(0.0, 1.0);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: negative
                ? [
                    scheme.errorContainer,
                    scheme.errorContainer.withValues(alpha: .55),
                  ]
                : [
                    scheme.primaryContainer,
                    scheme.primaryContainer.withValues(alpha: .55),
                  ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------ today (hero)
            Text(
              s.canSpendToday,
              style: theme.textTheme.titleSmall?.copyWith(
                color: onCard,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            AmountText(
              data.leftToday < 0 ? 0 : data.leftToday,
              millionsMode: millions,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: negative || overspent ? scheme.error : onCard,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: onCard.withValues(alpha: .14),
                color: overspent || negative ? scheme.error : scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              overspent
                  ? s.overspentToday(amount(-data.leftToday))
                  : data.todayBudget > 0 && data.leftToday == 0
                  ? s.todayBudgetUsed
                  : s.spentOfToday(
                      amount(data.spentToday),
                      amount(data.todayBudget),
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: overspent ? scheme.error : muted,
                fontWeight: overspent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),

            if (negative) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.negativeWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onCard,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ------------------------------------------- until pay day
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: onCard.withValues(alpha: .18)),
            ),
            // Wrap, not Row: on a narrow screen or with a large font the
            // days chip moves under the amount instead of crushing it.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.remaining,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AmountText(
                      data.remaining,
                      millionsMode: millions,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: negative ? scheme.error : onCard,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: onCard.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded, size: 15, color: onCard),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          s.daysToPayday(data.daysLeft),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${s.period}: ${formatRange(data.period.start, data.period.end)}',
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
