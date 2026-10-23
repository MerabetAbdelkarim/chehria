import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/budget.dart';
import '../providers/budgets_providers.dart';

/// Create or edit the monthly ceiling of one category.
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, this.budget});

  final Budget? budget;

  static Future<void> show(BuildContext context, {Budget? budget}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BudgetFormSheet(budget: budget),
    );
  }

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _limit;
  String? _categoryId;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    _limit = TextEditingController(
      text: budget == null ? '' : '${budget.limit}',
    );
    _categoryId = budget?.categoryId;
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final amountText = _limit.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);

    if (amountError != null || _categoryId == null) {
      setState(() => _error = amountError ?? s.selectCategory);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final month = _isEdit
        ? widget.budget!.month
        : ref.read(selectedMonthProvider);
    final budget = Budget(
      id: '',
      month: month,
      categoryId: _categoryId!,
      limit: int.parse(amountText),
      createdAt: _isEdit ? widget.budget!.createdAt : null,
    );

    try {
      await ref.read(budgetRepositoryProvider).save(uid, budget);
      if (!mounted) return;
      showAppSnack(context, s.budgetSaved);
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
      message: s.deleteBudgetConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(budgetRepositoryProvider).delete(uid, widget.budget!.id);
      if (!mounted) return;
      showAppSnack(context, s.budgetDeleted);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showAppSnack(context, s.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final categories = ref
        .watch(categoriesOrNullProvider)
        .where((c) => c.kind != CategoryKind.income)
        .toList();

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
              _isEdit ? s.editBudget : s.addBudget,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.setBudgetLimit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: InputDecoration(
                labelText: s.category,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name(isAr: s.isAr)),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _limit,
              label: s.budgetLimit,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.savings_outlined,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
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
