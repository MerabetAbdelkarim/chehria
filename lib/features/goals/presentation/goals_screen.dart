import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/goal.dart';
import '../providers/goals_providers.dart';
import 'goal_form_sheet.dart';
import 'goal_money_sheet.dart';

/// Savings envelopes with progress, deposits and withdrawals.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const GoalsScreen());

  Future<void> _delete(BuildContext context, WidgetRef ref, Goal goal) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteGoalConfirm,
    );
    if (!ok || !context.mounted) return;

    try {
      await ref.read(goalRepositoryProvider).delete(uid, goal.id);
      if (context.mounted) showAppSnack(context, s.goalDeleted);
    } catch (e, st) {
      reportError(e, st, reason: 'goals_screen');
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.goals)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoalFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addGoal),
      ),
      body: AsyncValueView(
        value: goals,
        onRetry: () => ref.invalidate(goalsProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.flag_outlined,
              title: s.noGoalsYet,
              subtitle: s.emptySubtitle,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: list.length,
            itemBuilder: (context, i) => _GoalTile(
              key: ValueKey(list[i].id),
              goal: list[i],
              onEdit: () => GoalFormSheet.show(context, goal: list[i]),
              onDelete: () => _delete(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);

    final color = goal.isCompleted
        ? const Color(0xFF00873D)
        : theme.colorScheme.primary;

    return Dismissible(
      key: ValueKey(goal.id),
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
                        goal.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.flag_outlined,
                        size: 19,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AmountText(
                      goal.savedAmount,
                      millionsMode: millions,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
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
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    color: color,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.isCompleted
                            ? s.goalCompleted
                            : '${s.remainingForGoal} ${formatAmount(goal.remaining, millionsMode: millions)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: goal.isCompleted
                              ? color
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: goal.isCompleted
                              ? FontWeight.w800
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (goal.deadline != null)
                      Text(
                        formatDateShort(goal.deadline!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      tooltip: s.withdraw,
                      visualDensity: VisualDensity.compact,
                      onPressed: goal.savedAmount <= 0
                          ? null
                          : () => GoalMoneySheet.show(
                              context,
                              goal: goal,
                              withdrawMode: true,
                            ),
                      icon: const Icon(Icons.arrow_downward_rounded, size: 19),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => GoalMoneySheet.show(context, goal: goal),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(s.deposit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
