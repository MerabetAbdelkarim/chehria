import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/dart_group.dart';
import '../providers/dart_providers.dart';
import 'dart_form_sheet.dart';
import 'dart_tile.dart';

/// One dawra: who paid this round, who receives, pay/receive actions.
class DartDetailScreen extends ConsumerWidget {
  const DartDetailScreen({super.key, required this.groupId});

  final String groupId;

  static Route<void> route(String groupId) => MaterialPageRoute<void>(
    builder: (_) => DartDetailScreen(groupId: groupId),
  );

  Future<void> _payContribution(
    BuildContext context,
    WidgetRef ref,
    DartGroup group,
  ) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final accountId = ref.read(defaultAccountProvider)?.id;
    if (accountId == null) {
      showAppSnack(context, s.pickAccount, error: true);
      return;
    }

    try {
      await ref
          .read(dartRepositoryProvider)
          .payContribution(
            uid: uid,
            group: group,
            memberName: group.meName,
            accountId: accountId,
            note: s.dawraContributionNote(
              group.name,
              group.meName,
              group.currentRound,
            ),
          );
      if (context.mounted) showAppSnack(context, s.contributionPaid);
    } catch (e, st) {
      reportError(e, st, reason: 'dart_detail_screen');
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  Future<void> _receive(
    BuildContext context,
    WidgetRef ref,
    DartGroup group, {
    required bool toMe,
  }) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final receiver = group.nextReceiver;
    if (receiver.isEmpty) return;

    final ok = await showConfirmDialog(
      context,
      title: s.markReceived,
      message:
          '${s.roundN} ${group.currentRound} — $receiver '
          '${formatDzd(group.pot)}',
      confirmLabel: s.confirm,
      destructive: false,
    );
    if (!ok || !context.mounted) return;

    final accountId = ref.read(defaultAccountProvider)?.id;
    if (accountId == null) {
      showAppSnack(context, s.pickAccount, error: true);
      return;
    }

    try {
      await ref
          .read(dartRepositoryProvider)
          .receiveRound(
            uid: uid,
            group: group,
            accountId: accountId,
            receiverName: receiver,
            toMe: toMe,
            note: s.dawraPotNote(group.name, receiver, group.currentRound),
          );
      if (context.mounted) showAppSnack(context, s.roundComplete);
    } catch (e, st) {
      reportError(e, st, reason: 'dart_detail_screen');
      if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final group = ref.watch(dartGroupProvider(groupId));

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.dartGroups)),
        body: group == null && ref.watch(dartGroupsProvider).isLoading
            ? LoadingView(label: s.loading)
            : ErrorView(message: s.errorGeneric),
      );
    }

    final millions = ref.watch(millionsModeProvider);
    final finished = group.isFinished;
    final iPaid = group.hasPaid(group.meName, group.currentRound);
    final iAmReceiver = group.nextReceiver == group.meName;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            tooltip: s.edit,
            onPressed: () => DartFormSheet.show(context, group: group),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ------------------------------------------------------ summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          finished
                              ? '${group.roundsDone} ${s.roundsDone}'
                              : '${s.currentRound} ${group.currentRound}/${group.memberCount}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${s.totalPot} ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AmountText(
                        group.pot,
                        millionsMode: millions,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    finished
                        ? contributionLabel(group, isAr: s.isAr)
                        : '${s.nextReceiver}: ${group.nextReceiver}'
                              ' • ${s.contributionAmount} '
                              '${formatAmount(group.contributionAmount, millionsMode: millions)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------- members
          Text(
            s.members,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < group.memberNames.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MemberRow(
                    group: group,
                    memberName: group.memberNames[i],
                    index: i,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------------------ actions
          if (!finished) ...[
            if (!iPaid)
              FilledButton.icon(
                onPressed: () => _payContribution(context, ref, group),
                icon: const Icon(Icons.payments_outlined),
                label: Text(
                  '${s.payContribution} — '
                  '${formatAmount(group.contributionAmount, millionsMode: millions)}',
                ),
              ),
            const SizedBox(height: 8),
            if (iAmReceiver)
              FilledButton.tonalIcon(
                onPressed: () => _receive(context, ref, group, toMe: true),
                icon: const Icon(Icons.savings_outlined),
                label: Text(
                  '${s.receiveRound} — '
                  '${formatAmount(group.pot, millionsMode: millions)}',
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _receive(context, ref, group, toMe: false),
                icon: const Icon(Icons.card_giftcard_outlined),
                label: Text(
                  '${s.recordSomeoneReceived}: ${group.nextReceiver}',
                ),
              ),
            if (!iPaid) ...[
              const SizedBox(height: 6),
              Text(
                s.dartPaymentsHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ] else
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFF00873D),
                ),
                title: Text(
                  s.goalCompleted,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text('${group.roundsDone} ${s.roundsDone}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.group,
    required this.memberName,
    required this.index,
  });

  final DartGroup group;
  final String memberName;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);

    final isMe = memberName == group.meName;
    final receiver = !group.isFinished && group.nextReceiver == memberName;
    final paid = group.hasPaid(memberName, group.currentRound);

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: receiver
            ? theme.colorScheme.primary.withValues(alpha: .14)
            : theme.colorScheme.surfaceContainerHighest,
        child: Text(
          '${index + 1}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: receiver
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(
        isMe ? '$memberName (${s.iAm})' : memberName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: receiver ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      subtitle: receiver ? Text(s.nextReceiver) : null,
      trailing: group.isFinished
          ? null
          : Icon(
              paid
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: paid ? const Color(0xFF00873D) : theme.colorScheme.outline,
            ),
    );
  }
}
