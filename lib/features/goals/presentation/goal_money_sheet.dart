import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/models/account.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../models/goal.dart';

/// Deposit into (or withdraw from) a goal envelope.
class GoalMoneySheet extends ConsumerStatefulWidget {
  const GoalMoneySheet({
    super.key,
    required this.goal,
    required this.withdrawMode,
  });

  final Goal goal;
  final bool withdrawMode;

  static Future<void> show(
    BuildContext context, {
    required Goal goal,
    bool withdrawMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GoalMoneySheet(goal: goal, withdrawMode: withdrawMode),
    );
  }

  @override
  ConsumerState<GoalMoneySheet> createState() => _GoalMoneySheetState();
}

class _GoalMoneySheetState extends ConsumerState<GoalMoneySheet> {
  late final TextEditingController _amount;
  String? _accountId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _accountId = ref.read(defaultAccountProvider)?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final amountText = _amount.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);

    if (amountError != null || _accountId == null) {
      setState(() => _error = amountError ?? s.selectAccount);
      return;
    }

    final amount = int.parse(amountText);
    final account = ref.read(accountByIdProvider(_accountId!));

    if (widget.withdrawMode && amount > widget.goal.savedAmount) {
      setState(() => _error = s.withdrawAmountCantExceed);
      return;
    }
    if (!widget.withdrawMode && account != null && amount > account.balance) {
      setState(() => _error = s.depositAmountCantExceed);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final repo = ref.read(goalRepositoryProvider);
    try {
      if (widget.withdrawMode) {
        await repo.withdraw(
          uid: uid,
          goal: widget.goal,
          amount: amount,
          accountId: _accountId!,
        );
      } else {
        await repo.deposit(
          uid: uid,
          goal: widget.goal,
          amount: amount,
          accountId: _accountId!,
        );
      }
      if (!mounted) return;
      showAppSnack(
        context,
        widget.withdrawMode ? s.withdrawSaved : s.depositSaved,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = s.errorGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsOrNullProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.withdrawMode ? s.withdraw : s.deposit,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.goal.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _amount,
              label: s.amount,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: widget.withdrawMode
                    ? s.addToBalance
                    : s.depositFromAccount,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              items: [
                for (final Account a in accounts)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      '${a.name} — ${a.balance} دج',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(s.save),
            ),
          ],
        ),
      ),
    );
  }
}
