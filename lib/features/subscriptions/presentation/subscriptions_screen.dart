import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../domain/subscription_calculator.dart';
import '../models/subscription.dart';
import '../providers/subscriptions_providers.dart';
import 'subscription_form_sheet.dart';

/// Recurring bills: due dates, "pay now" and pause/resume.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const SubscriptionsScreen());

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteSubscriptionConfirm,
    );
    if (!ok || !context.mounted) return;

    try {
      await ref.read(subscriptionRepositoryProvider).delete(uid, sub.id);
      if (context.mounted) showAppSnack(context, s.subscriptionDeleted);
    } catch (_) {
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  Future<void> _payNow(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final accountId = sub.accountId ?? ref.read(defaultAccountProvider)?.id;
    if (accountId == null) {
      showAppSnack(context, s.pickAccount, error: true);
      return;
    }

    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .recordPayment(uid: uid, sub: sub, accountId: accountId);
      if (context.mounted) showAppSnack(context, s.subscriptionPaid);
    } catch (_) {
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final subs = ref.watch(subscriptionsProvider);
    final now = ref.watch(nowProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.subscriptions)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SubscriptionFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addSubscription),
      ),
      body: AsyncValueView(
        value: subs,
        onRetry: () => ref.invalidate(subscriptionsProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.autorenew_rounded,
              title: s.noSubscriptions,
              subtitle: s.emptySubtitle,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: list.length,
            itemBuilder: (context, i) => _SubTile(
              key: ValueKey(list[i].id),
              sub: list[i],
              now: now,
              onPay: () => _payNow(context, ref, list[i]),
              onEdit: () => SubscriptionFormSheet.show(context, sub: list[i]),
              onDelete: () => _delete(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SubTile extends ConsumerWidget {
  const _SubTile({
    super.key,
    required this.sub,
    required this.now,
    required this.onPay,
    required this.onEdit,
    required this.onDelete,
  });

  final Subscription sub;
  final DateTime now;
  final Future<void> Function() onPay;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);

    final days = sub.daysUntilNow(now);
    final String dueLabel;
    final Color dueColor;
    if (!sub.isActive) {
      dueLabel = s.pausedSubscription;
      dueColor = theme.colorScheme.outline;
    } else if (sub.isOverdueNow(now)) {
      dueLabel = s.overdue;
      dueColor = theme.colorScheme.error;
    } else if (sub.isDueTodayNow(now)) {
      dueLabel = s.dueToday;
      dueColor = theme.colorScheme.error;
    } else if (days == 1) {
      dueLabel = s.dueTomorrow;
      dueColor = theme.colorScheme.tertiary;
    } else {
      dueLabel = formatDateShort(sub.nextDueDate);
      dueColor = theme.colorScheme.onSurfaceVariant;
    }

    final cycleLabel = switch (sub.cycle) {
      SubscriptionCycle.weekly => s.cycleWeekly,
      SubscriptionCycle.monthly => s.cycleMonthly,
      SubscriptionCycle.yearly => s.cycleYearly,
    };

    return Dismissible(
      key: ValueKey(sub.id),
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
        child: ListTile(
          onTap: onEdit,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: .14),
            child: Icon(
              Icons.autorenew_rounded,
              size: 21,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            sub.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '$cycleLabel • $dueLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: dueColor),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountText(
                sub.amount,
                millionsMode: millions,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: s.markPaid,
                onPressed: sub.isActive ? () => onPay() : null,
                icon: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 22,
                  color: sub.isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
