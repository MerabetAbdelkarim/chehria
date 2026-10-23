import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../goals/models/goal.dart';
import '../../../goals/presentation/goals_screen.dart';
import '../../../goals/providers/goals_providers.dart';
import '../../../settings/providers/settings_providers.dart';

/// Top savings goals with progress, shown under the pay-period summary.
class GoalsCard extends ConsumerWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final goals = ref.watch(activeGoalsProvider);

    if (goals.isEmpty) return const SizedBox.shrink();

    final top = goals.take(3).toList();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(GoalsScreen.route()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.goals,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final goal in top) ...[
                _GoalLine(goal: goal, millions: millions),
                if (!identical(goal, top.last)) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({required this.goal, required this.millions});

  final Goal goal;
  final bool millions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AmountText(
              goal.savedAmount,
              millionsMode: millions,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              ' / ${formatAmount(goal.targetAmount, millionsMode: millions)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 6,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
