import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../goals/models/goal.dart';
import '../../goals/presentation/goal_form_sheet.dart';
import '../../goals/providers/goals_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../domain/algerian_events.dart';

/// Upcoming Algerian events with a "prepare early" savings plan.
class SeasonalScreen extends ConsumerWidget {
  const SeasonalScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const SeasonalScreen());

  void _createGoal(BuildContext context, WidgetRef ref, SeasonalEvent event) {
    GoalFormSheet.show(
      context,
      initialName: event.name(isAr: ref.read(sProvider).isAr),
      initialDeadline: event.date,
      initialKind: GoalKind.seasonal,
      initialEventId: event.id,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final now = ref.watch(nowProvider);
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.seasonal)),
      body: AsyncValueView(
        value: goals,
        onRetry: () => ref.invalidate(goalsProvider),
        data: (goalList) {
          final events = upcomingEvents(now);
          if (events.isEmpty) {
            return EmptyView(
              icon: Icons.beach_access_outlined,
              title: s.noUpcomingEvents,
              subtitle: s.seasonalHint,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Text(
                s.seasonalHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final event in events) ...[
                _EventCard(
                  event: event,
                  now: now,
                  goal: _goalFor(goalList, event),
                  onCreateGoal: () => _createGoal(context, ref, event),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Goal? _goalFor(List<Goal> goals, SeasonalEvent event) {
    for (final goal in goals) {
      if (goal.kind == GoalKind.seasonal && goal.eventId == event.id) {
        return goal;
      }
    }
    return null;
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({
    required this.event,
    required this.now,
    required this.goal,
    required this.onCreateGoal,
  });

  final SeasonalEvent event;
  final DateTime now;
  final Goal? goal;
  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);

    final days = daysLeft(now, event.date);
    final setAside = goal == null
        ? 0
        : monthlySetAside(
            target: goal!.targetAmount,
            saved: goal!.savedAmount,
            now: now,
            date: event.date,
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.celebration_outlined,
                    size: 19,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.name(isAr: s.isAr),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$days ${s.daysLeft}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: days <= 30
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatDateLong(event.date, isAr: s.isAr),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (goal != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal!.progress,
                  minHeight: 8,
                  color: theme.colorScheme.tertiary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  AmountText(
                    goal!.savedAmount,
                    millionsMode: millions,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    ' / ${formatAmount(goal!.targetAmount, millionsMode: millions)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (setAside > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${s.monthlySetAside}: ${formatAmount(setAside, millionsMode: millions)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onCreateGoal,
                  icon: const Icon(Icons.flag_outlined, size: 17),
                  label: Text(s.createGoalForEvent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
