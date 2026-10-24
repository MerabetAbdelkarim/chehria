import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_reporter.dart';
import '../../../../core/localization/s.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../accounts/providers/accounts_providers.dart';
import '../../../debts/presentation/debt_payment_sheet.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../../subscriptions/models/subscription.dart';
import '../../providers/home_providers.dart';

/// Everything to pay before the next pay day (bills and debts I owe), soonest
/// first. Tapping a bill marks it paid; tapping a debt records a payment.
class BeforePaydayCard extends ConsumerWidget {
  const BeforePaydayCard({super.key});

  static const int _shown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final now = ref.watch(nowProvider);
    final items = ref.watch(beforePaydayProvider);

    var total = 0;
    for (final item in items) {
      total += item.dueAmount;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.beforePayday,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (total > 0)
                  AmountText(
                    total,
                    millionsMode: millions,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Color(0xFF00873D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.nothingBeforePayday,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const SizedBox(height: 4),
              for (final item in items.take(_shown))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 17,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      item.isBill
                          ? Icons.autorenew_rounded
                          : Icons.handshake_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${item.isBill ? s.billDue : s.debtDue} · '
                    '${_dueLabel(s, item.dueDate, now)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isLate(item.dueDate, now)
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: AmountText(
                    item.dueAmount,
                    millionsMode: millions,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => item.isBill
                      ? _payBill(context, ref, item.subscription!)
                      : DebtPaymentSheet.show(context, item.debt!),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isLate(DateTime due, DateTime now) =>
      _day(due).isBefore(_day(now));

  static String _dueLabel(S s, DateTime due, DateTime now) {
    final days = _day(due).difference(_day(now)).inDays;
    if (days < 0) return s.overdue;
    if (days == 0) return s.dueToday;
    if (days == 1) return s.dueTomorrow;
    return formatDateShort(due);
  }

  Future<void> _payBill(
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
    } catch (e, st) {
      reportError(e, st, reason: 'before_payday_card');
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }
}
