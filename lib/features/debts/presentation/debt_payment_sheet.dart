import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/debt.dart';

/// Records a partial (or full) payment against a debt in one batch.
class DebtPaymentSheet extends ConsumerStatefulWidget {
  const DebtPaymentSheet({super.key, required this.debt});

  final Debt debt;

  static Future<void> show(BuildContext context, Debt debt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DebtPaymentSheet(debt: debt),
    );
  }

  @override
  ConsumerState<DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends ConsumerState<DebtPaymentSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  String? _accountId;
  bool _saving = false;
  String? _error;

  Debt get _debt => widget.debt;
  bool get _receiving => _debt.type == DebtType.owedToMe;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _note = TextEditingController();
    _date = DateTime.now();
    _accountId = ref.read(defaultAccountProvider)?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _fillRemaining() {
    setState(() => _amount.text = '${_debt.remaining}');
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final amountText = _amount.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);
    if (amountError != null) {
      setState(() => _error = amountError);
      return;
    }
    final amount = int.parse(amountText);
    if (amount > _debt.remaining) {
      setState(() => _error = s.paymentsTotalHint);
      return;
    }
    if (_accountId == null) {
      setState(() => _error = s.selectAccount);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final userNote = _note.text.trim();
    final ledgerNote = userNote.isNotEmpty
        ? userNote
        : _debt.type == DebtType.owedToMe
        ? s.debtPaymentReceivedNote(_debt.person)
        : s.debtPaymentPaidNote(_debt.person);

    try {
      await ref
          .read(debtRepositoryProvider)
          .addPayment(
            uid: uid,
            debt: _debt,
            amount: amount,
            accountId: _accountId!,
            date: _date,
            note: ledgerNote,
            paymentNote: userNote,
          );
      if (!mounted) return;
      showAppSnack(context, s.paymentSaved);
      Navigator.of(context).pop();
    } catch (e, st) {
      reportError(e, st, reason: 'debt_payment_sheet');
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
    final millions = ref.watch(millionsModeProvider);

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_receiving ? s.collectDebt : s.payDebt} — ${_debt.person}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: .5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.totalAmount,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AmountText(
                          _debt.amount,
                          millionsMode: millions,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.paidAmount,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AmountText(
                          _debt.paidTotal,
                          millionsMode: millions,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00873D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.amountRemaining,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AmountText(
                          _debt.remaining,
                          millionsMode: millions,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _amount,
              label: s.amount,
              hint: s.paymentAmountHint,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
              suffixIcon: TextButton(
                onPressed: _fillRemaining,
                child: Text(s.amountRemaining),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: s.selectAccount,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _note,
              label: s.note,
              hint: s.notePlaceholder,
              prefixIcon: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(s.date),
              trailing: Text(
                formatDateShort(_date),
                style: theme.textTheme.titleSmall,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            if (_debt.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.paymentsHistory,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              for (final p in _debt.payments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDateShort(p.date),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      AmountText(
                        p.amount,
                        millionsMode: millions,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
            FilledButton.icon(
              onPressed: _saving || _debt.remaining <= 0 ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Icon(
                      _receiving
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                    ),
              label: Text(s.recordPayment),
            ),
          ],
        ),
      ),
    );
  }
}
