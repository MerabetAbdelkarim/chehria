import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_data.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../core/localization/s.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../models/account.dart';

/// Create / edit / delete a wallet.
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.account});

  final Account? account;

  static Future<void> show(BuildContext context, {Account? account}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AccountFormSheet(account: account),
    );
  }

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late AccountType _type;
  late int _color;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name = TextEditingController(text: account?.name ?? '');
    _balance = TextEditingController(
      text: (account?.balance ?? 0).abs().toString(),
    );
    _type = account?.type ?? AccountType.cash;
    _color = account?.colorValue ?? DefaultData.colorOptions.first.toARGB32();
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  String _typeLabel(AccountType type, S s) {
    switch (type) {
      case AccountType.cash:
        return s.cash;
      case AccountType.ccp:
        return s.ccp;
      case AccountType.card:
        return s.bankCard;
      case AccountType.other:
        return s.other;
    }
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    if (_name.text.trim().isEmpty) {
      setState(() => _error = s.fieldRequired(s.accountName));
      return;
    }
    final balance =
        int.tryParse(_balance.text.trim().replaceAll(RegExp(r'[^\d-]'), '')) ??
        0;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(accountRepositoryProvider);
      if (_isEdit) {
        final updated = widget.account!.copyWith(
          name: _name.text.trim(),
          type: _type,
          colorValue: _color,
        );
        await repo.update(uid, updated);
      } else {
        await repo.create(
          uid,
          Account(
            id: '',
            name: _name.text.trim(),
            type: _type,
            balance: balance,
            colorValue: _color,
          ),
        );
      }
      if (!mounted) return;
      showAppSnack(context, s.savedDone);
      Navigator.of(context).pop();
    } catch (e, st) {
      reportError(e, st, reason: 'account_form_sheet');
      if (mounted) setState(() => _error = s.errorGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    final account = widget.account;
    if (uid == null || account == null) return;

    final inUse = await ref
        .read(accountRepositoryProvider)
        .isInUse(uid, account.id);
    if (!mounted) return;
    if (inUse) {
      showAppSnack(context, s.accountInUse, error: true);
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteAccountConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(accountRepositoryProvider).delete(uid, account.id);
      if (!mounted) return;
      showAppSnack(context, s.deletedDone);
      Navigator.of(context).pop();
    } catch (e, st) {
      reportError(e, st, reason: 'account_form_sheet');
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);

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
              _isEdit ? s.editAccount : s.addAccount,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: s.accountName,
              prefixIcon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: s.accountType,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: [
                for (final type in AccountType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabel(type, s)),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 14),
            if (!_isEdit)
              AppTextField(
                controller: _balance,
                label: s.initialBalance,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_rounded,
              ),
            const SizedBox(height: 16),
            Text(
              s.color,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in DefaultData.colorOptions)
                  InkWell(
                    onTap: () => setState(() => _color = color.toARGB32()),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color.toARGB32()
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _color == color.toARGB32()
                          ? Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
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
              const SizedBox(height: 6),
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
