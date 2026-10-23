import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/money_transaction.dart';

/// Full edit form for an existing operation (tap a row in the list).
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, required this.txn});

  final MoneyTransaction txn;

  static Future<void> show(BuildContext context, MoneyTransaction txn) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionFormSheet(txn: txn),
    );
  }

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late TxnType _type;
  late DateTime _date;
  String? _categoryId;
  String? _accountId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final txn = widget.txn;
    _amount = TextEditingController(text: txn.amount.toString());
    _note = TextEditingController(text: txn.note);
    _type = txn.type;
    _date = txn.date;
    _categoryId = txn.categoryId;
    _accountId = txn.accountId ?? txn.toAccountId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final amountText = _amount.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);
    if (amountError != null) {
      setState(() => _error = amountError);
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

    final updated = widget.txn.copyWith(
      type: _type,
      amount: int.parse(amountText),
      date: _date,
      categoryId: _categoryId,
      accountId: _accountId,
      note: _note.text.trim(),
    );

    try {
      await ref.read(transactionRepositoryProvider).update(uid, updated);
      if (!mounted) return;
      showAppSnack(context, s.savedDone);
      Navigator.of(context).pop();
    } catch (_) {
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
      message: s.deleteTransactionConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(transactionRepositoryProvider).delete(uid, widget.txn);
      if (!mounted) return;
      showAppSnack(context, s.transactionDeleted);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesOrNullProvider);
    final accounts = ref.watch(accountsOrNullProvider);

    final usableCategories = categories.where((c) {
      if (_type == TxnType.income) return c.kind != CategoryKind.expense;
      if (_type == TxnType.expense) return c.kind != CategoryKind.income;
      return true;
    }).toList();

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
              s.editTransaction,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (_type != TxnType.transfer)
              SegmentedButton<TxnType>(
                segments: [
                  ButtonSegment(value: TxnType.expense, label: Text(s.expense)),
                  ButtonSegment(
                    value: TxnType.income,
                    label: Text(s.incomeShort),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() {
                  _type = v.first;
                  _categoryId = null;
                }),
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
              initialValue: _categoryId,
              decoration: InputDecoration(
                labelText: s.categoryName,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: [
                for (final c in usableCategories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name(isAr: s.isAr)),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: s.account,
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
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(s.date),
              trailing: Text(
                '${_date.day.toString().padLeft(2, '0')}/'
                '${_date.month.toString().padLeft(2, '0')}/'
                '${_date.year}',
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
        ),
      ),
    );
  }
}
