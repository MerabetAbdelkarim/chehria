import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_data.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../accounts/models/account.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/categories_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/money_transaction.dart';

/// Two-tap add: type the amount, tap the category — done.
class FastAddTransactionScreen extends ConsumerStatefulWidget {
  const FastAddTransactionScreen({super.key});

  @override
  ConsumerState<FastAddTransactionScreen> createState() =>
      _FastAddTransactionScreenState();
}

class _FastAddTransactionScreenState
    extends ConsumerState<FastAddTransactionScreen> {
  String _digits = '';
  TxnType _type = TxnType.expense;
  DateTime _date = DateTime.now();
  String? _accountId;
  String? _note;

  int get _amount => int.tryParse(_digits) ?? 0;

  void _tap(String key) {
    setState(() {
      if (key == 'del') {
        if (_digits.isNotEmpty) {
          _digits = _digits.substring(0, _digits.length - 1);
        }
      } else if (key == '00') {
        if (_digits.isNotEmpty && _digits.length < 12) _digits += '00';
      } else if (_digits.length < 12) {
        _digits += key;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(Category category) async {
    final s = ref.read(sProvider);
    if (_amount <= 0) {
      showAppSnack(context, s.invalidAmount, error: true);
      return;
    }
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final accountId = _accountId ?? ref.read(defaultAccountProvider)?.id;
    if (accountId == null) {
      showAppSnack(context, s.pickAccount, error: true);
      return;
    }

    final txn = MoneyTransaction(
      id: '',
      type: _type,
      amount: _amount,
      date: _date,
      categoryId: category.id,
      accountId: accountId,
      note: _note ?? '',
    );

    try {
      await ref.read(transactionRepositoryProvider).add(uid, txn);
      if (!mounted) return;
      showAppSnack(context, s.transactionSaved);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final millions = ref.watch(millionsModeProvider);
    final categories = ref.watch(categoriesOrNullProvider);
    final accounts = ref.watch(accountsOrNullProvider);

    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }

    final accountLabel = accounts.isEmpty
        ? s.selectAccount
        : accounts
              .firstWhere(
                (a) => a.id == _accountId,
                orElse: () => accounts.first,
              )
              .name;

    final visibleCategories = categories.where((c) {
      if (_type == TxnType.income) return c.kind != CategoryKind.expense;
      return c.kind != CategoryKind.income;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.addTransaction)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<TxnType>(
                segments: [
                  ButtonSegment(value: TxnType.expense, label: Text(s.expense)),
                  ButtonSegment(
                    value: TxnType.income,
                    label: Text(s.incomeShort),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  Text(
                    _amount == 0
                        ? '0 ${AppConstants.currencySymbol}'
                        : formatAmount(_amount, millionsMode: millions),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _amount == 0
                          ? theme.colorScheme.outline
                          : (_type == TxnType.income
                                ? const Color(0xFF00873D)
                                : theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: accountLabel,
                        onTap: accounts.isEmpty ? null : _pickAccount,
                      ),
                      const SizedBox(width: 8),
                      _MiniChip(
                        icon: Icons.event_outlined,
                        label: formatDateRelative(
                          _date,
                          DateTime.now(),
                          isAr: s.isAr,
                        ),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: s.notePlaceholder,
                  counterText: '',
                ),
                maxLength: 120,
                onChanged: (v) => _note = v.trim(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  s.selectCategory,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: visibleCategories.isEmpty
                  ? EmptyView(
                      icon: Icons.category_outlined,
                      title: s.noCategories,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 112,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: .92,
                          ),
                      itemCount: visibleCategories.length,
                      itemBuilder: (context, i) {
                        final c = visibleCategories[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _save(c),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: Color(
                                    c.colorValue,
                                  ).withValues(alpha: .18),
                                  child: Icon(
                                    DefaultData.iconOf(c.iconCode),
                                    color: Color(c.colorValue),
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.name(isAr: s.isAr),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            _KeyPad(onTap: _tap),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAccount() async {
    final s = ref.read(sProvider);
    final accounts = ref.read(accountsOrNullProvider);
    final selected = await showModalBottomSheet<Account>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s.selectAccount,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final account in accounts)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    account.colorValue,
                  ).withValues(alpha: .18),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(account.colorValue),
                  ),
                ),
                title: Text(account.name),
                subtitle: AmountText(account.balance),
                onTap: () => Navigator.pop(context, account),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _accountId = selected.id);
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: .5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple numeric keypad.
class _KeyPad extends StatelessWidget {
  const _KeyPad({required this.onTap});

  final void Function(String key) onTap;

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '00',
    '0',
    'del',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      color: theme.colorScheme.surface,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 2.6,
        children: [
          for (final key in _keys)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(key),
              child: Center(
                child: key == 'del'
                    ? const Icon(Icons.backspace_outlined)
                    : Text(
                        key,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
