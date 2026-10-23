import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/dart_group.dart';

/// Compact card listing one dawra on the dart screen.
class DartTile extends ConsumerWidget {
  const DartTile({super.key, required this.group, required this.onTap});

  final DartGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);

    final done = group.isFinished;
    final color = done ? theme.colorScheme.outline : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .14),
          child: Icon(Icons.groups_outlined, size: 21, color: color),
        ),
        title: Text(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          done
              ? '${group.roundsDone} ${s.roundsDone}'
              : '${s.currentRound} ${group.currentRound}/${group.memberCount}'
                    ' â€¢ ${s.nextReceiver}: ${group.nextReceiver}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: done
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AmountText(
              group.contributionAmount,
              millionsMode: millions,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${group.memberCount} ${s.members}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Human-readable contribution label reused across dart screens.
String contributionLabel(DartGroup group, {required bool isAr}) => isAr
    ? 'ÙƒÙ„ Ø¹Ø¶Ùˆ ${group.contributionAmount} Ø¯Ø¬'
    : '${group.contributionAmount} DA / membre';

/// `12/10/2026` label for payment dates.
String dartDate(DateTime date) => formatDateShort(date);
