import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../domain/subscription_calculator.dart';
import '../models/subscription.dart';

/// Create or edit a recurring bill.
class SubscriptionFormSheet extends ConsumerStatefulWidget {
  const SubscriptionFormSheet({super.key, this.sub});

  final Subscription? sub;

  static Future<void> show(BuildContext context, {Subscription? sub}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SubscriptionFormSheet(sub: sub),
    );
  }

  @override
  ConsumerState<SubscriptionFormSheet> createState() =>
      _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends ConsumerState<SubscriptionFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late SubscriptionCycle _cycle;
  late DateTime _nextDueDate;
  String? _categoryId;
  String? _accountId;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.sub != null;

  @override
  void initState() {
    super.initState();
    final sub = widget.sub;
    _name = TextEditingController(text: sub?.name ?? '');
    _amount = TextEditingController(text: sub == null ? '' : '${sub.amount}');
    _note = TextEditingController(text: sub?.note ?? '');
    _cycle = sub?.cycle ?? SubscriptionCycle.monthly;
    _nextDueDate = sub?.nextDueDate ?? DateTime.now();
    _categoryId = sub?.categoryId;
    _accountId = sub?.accountId;
    _isActive = sub?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final nameError = validateName(s, _name.text, s.subscriptionName);
    final amountText = _amount.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);
    if (nameError != null || amountError != null) {
      setState(() => _error = nameError ?? amountError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final amount = int.parse(amountText);
    final repo = ref.read(subscriptionRepositoryProvider);

    try {
      if (_isEdit) {
        await repo.update(
          uid,
          Subscription(
            id: widget.sub!.id,
            name: _name.text.trim(),
            amount: amount,
            cycle: _cycle,
            nextDueDate: _nextDueDate,
            categoryId: _categoryId,
            accountId: _accountId,
            isActive: _isActive,
            note: _note.text.trim(),
            lastPaidAt: widget.sub!.lastPaidAt,
            createdAt: widget.sub!.createdAt,
          ),
        );
      } else {
        final sub = Subscription(
          id: '',
          name: _name.text.trim(),
          amount: amount,
          cycle: _cycle,
          nextDueDate: _nextDueDate,
          categoryId: _categoryId,
          accountId: _accountId,
          note: _note.text.trim(),
        );
        await repo.create(uid, sub);
      }
      if (!mounted) return;
      showAppSnack(context, s.subscriptionSaved);
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
      message: s.deleteSubscriptionConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .delete(uid, widget.sub!.id);
      if (!mounted) return;
      showAppSnack(context, s.subscriptionDeleted);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsOrNullProvider);
    final categories = ref.watch(categoriesOrNullProvider);

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
              _isEdit ? s.editSubscription : s.addSubscription,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: s.subscriptionName,
              hint: 'CFA / Internet / Netflix …',
              prefixIcon: Icons.label_outline_rounded,
              validator: (v) => validateName(s, v ?? '', s.subscriptionName),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _amount,
              label: s.amount,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
            ),
            const SizedBox(height: 14),
            Text(
              s.billingCycle,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SubscriptionCycle>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: SubscriptionCycle.weekly,
                  label: Text(s.cycleWeekly),
                ),
                ButtonSegment(
                  value: SubscriptionCycle.monthly,
                  label: Text(s.cycleMonthly),
                ),
                ButtonSegment(
                  value: SubscriptionCycle.yearly,
                  label: Text(s.cycleYearly),
                ),
              ],
              selected: {_cycle},
              onSelectionChanged: (v) => setState(() => _cycle = v.first),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(s.nextDueDate),
              trailing: Text(
                '${_nextDueDate.day.toString().padLeft(2, '0')}/'
                '${_nextDueDate.month.toString().padLeft(2, '0')}/'
                '${_nextDueDate.year}',
                style: theme.textTheme.titleSmall,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDueDate,
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _nextDueDate = picked);
              },
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: InputDecoration(
                labelText: s.selectCategory,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name(isAr: s.isAr)),
                  ),
                DropdownMenuItem(value: '', child: Text(s.uncategorized)),
              ],
              onChanged: (v) => setState(
                () => _categoryId = (v == null || v.isEmpty) ? null : v,
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
            if (_isEdit) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _isActive ? s.activeSubscription : s.pausedSubscription,
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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
