import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../accounts/providers/accounts_providers.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../../subscriptions/models/subscription.dart';
import '../../../subscriptions/presentation/subscriptions_screen.dart';
import '../../../subscriptions/providers/subscriptions_providers.dart';

/// Recurring bills falling due before the next pay day, with a "pay" action.
class UpcomingBillsCard extends ConsumerWidget {
  const UpcomingBillsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final due = ref.watch(subscriptionsDueProvider);

    if (due.isEmpty) return const SizedBox.shrink();

    var total = 0;
    for (final sub in due) {
      total += sub.amount;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.autorenew_rounded,
                  size: 19,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.upcomingBills,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AmountText(
                  total,
                  millionsMode: millions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final sub in due.take(4))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  sub.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _dueLabel(context, ref, sub),
                  style: theme.textTheme.bodySmall,
                ),
                trailing: AmountText(
                  sub.amount,
                  millionsMode: millions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => _pay(context, ref, sub),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(SubscriptionsScreen.route()),
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text(s.subscriptions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dueLabel(BuildContext context, WidgetRef ref, Subscription sub) {
    final s = ref.watch(sProvider);
    final now = ref.watch(nowProvider);
    if (sub.isOverdueNow(now)) return s.overdue;
    if (sub.isDueTodayNow(now)) return s.dueToday;
    if (sub.daysUntilNow(now) == 1) return s.dueTomorrow;
    return formatDateShort(sub.nextDueDate);
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final ok = await showConfirmDialog(
      context,
      title: s.markPaid,
      message: '${sub.name} — ${formatDzd(sub.amount)}',
      destructive: false,
      confirmLabel: s.confirm,
    );
    if (!ok || !context.mounted) return;

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
}
