import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/localization/s_context.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../models/debt.dart';

/// Create or edit a debt of either direction (tap FAB / tap a row).
class DebtFormSheet extends ConsumerStatefulWidget {
  const DebtFormSheet({super.key, this.debt});

  final Debt? debt;

  static Future<void> show(BuildContext context, {Debt? debt}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DebtFormSheet(debt: debt),
    );
  }

  @override
  ConsumerState<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<DebtFormSheet> {
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _phone;
  late final TextEditingController _note;
  late DebtType _type;
  late DateTime _date;
  DateTime? _dueDate;
  bool _addToBalance = false;
  String? _balanceAccountId;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _person = TextEditingController(text: debt?.person ?? '');
    _amount = TextEditingController(text: debt == null ? '' : '${debt.amount}');
    _phone = TextEditingController(text: debt?.phone ?? '');
    _note = TextEditingController(text: debt?.note ?? '');
    _type = debt?.type ?? DebtType.iOwe;
    _date = debt?.date ?? DateTime.now();
    _dueDate = debt?.dueDate;
    _addToBalance = debt?.addToBalance ?? false;
    _balanceAccountId = null;
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final personError = validateName(s, _person.text, s.person);
    final amountText = _amount.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);

    if (personError != null || amountError != null) {
      setState(() => _error = personError ?? amountError);
      return;
    }
    if (_addToBalance && _balanceAccountId == null) {
      setState(() => _error = s.selectAccount);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final repo = ref.read(debtRepositoryProvider);
    final amount = int.parse(amountText);

    try {
      if (_isEdit) {
        final updated = Debt(
          id: widget.debt!.id,
          type: widget.debt!.type,
          person: _person.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          amount: amount,
          date: _date,
          dueDate: _dueDate,
          note: _note.text.trim(),
          payments: widget.debt!.payments,
          addToBalance: widget.debt!.addToBalance,
          balanceAccountId: widget.debt!.balanceAccountId,
          createdAt: widget.debt!.createdAt,
        );
        await repo.update(uid, widget.debt!, updated);
      } else {
        final debt = Debt(
          id: '',
          type: _type,
          person: _person.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          amount: amount,
          date: _date,
          dueDate: _dueDate,
          note: _note.text.trim(),
          addToBalance: _addToBalance,
        );
        await repo.create(uid, debt, balanceAccountId: _balanceAccountId);
      }
      if (!mounted) return;
      showAppSnack(context, s.debtSaved);
      Navigator.of(context).pop();
    } catch (e, st) {
      reportError(e, st, reason: 'debt_form_sheet');
      if (mounted) setState(() => _error = s.errorGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteDebtConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(debtRepositoryProvider).delete(uid, widget.debt!);
      if (!mounted) return;
      showAppSnack(context, s.debtDeleted);
      Navigator.of(context).pop();
    } catch (e, st) {
      reportError(e, st, reason: 'debt_form_sheet');
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
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
              _isEdit ? s.editDebt : s.addDebt,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEdit) ...[
              SegmentedButton<DebtType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: DebtType.iOwe, label: Text(s.iOwe)),
                  ButtonSegment(
                    value: DebtType.owedToMe,
                    label: Text(s.owedToMe),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _person,
              label: s.person,
              hint: s.personHint,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => validateName(s, v ?? '', s.person),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _amount,
              label: s.totalAmount,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _phone,
              label: s.phone,
              hint: '05 …',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),
            _DateTile(
              label: s.date,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 8),
            _DateTile(
              label: s.dueDate,
              value: _dueDate,
              onClear: () => setState(() => _dueDate = null),
              onChanged: (d) => setState(() => _dueDate = d),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _note,
              label: s.note,
              hint: s.notePlaceholder,
              prefixIcon: Icons.notes_rounded,
              maxLines: 2,
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.addToBalance),
                subtitle: Text(
                  s.addToBalanceHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _addToBalance,
                onChanged: (v) => setState(() {
                  _addToBalance = v;
                  if (v && _balanceAccountId == null) {
                    _balanceAccountId = ref.read(defaultAccountProvider)?.id;
                  }
                }),
              ),
              if (_addToBalance)
                DropdownButtonFormField<String>(
                  initialValue: _balanceAccountId,
                  decoration: InputDecoration(
                    labelText: s.selectAccount,
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  items: [
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _balanceAccountId = v),
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
            if (_isEdit) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  s.delete,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Date row with a picker; optional "clear" for the due date.
class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null
        ? context.s.optional
        : '${value!.day.toString().padLeft(2, '0')}/'
              '${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: onClear,
            ),
          Text(text, style: theme.textTheme.titleSmall),
        ],
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
