import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_data.dart';
import '../../../core/localization/s.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../models/category.dart';

/// Create / edit / delete a category (name, icon, color, kind).
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.category});

  final Category? category;

  static Future<void> show(BuildContext context, {Category? category}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CategoryFormSheet(category: category),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameAr;
  late final TextEditingController _nameFr;
  late CategoryKind _kind;
  late int _icon;
  late int _color;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameAr = TextEditingController(text: category?.nameAr ?? '');
    _nameFr = TextEditingController(text: category?.nameFr ?? '');
    _kind = category?.kind ?? CategoryKind.both;
    _icon = category?.iconCode ?? Icons.category.codePoint;
    _color = category?.colorValue ?? DefaultData.colorOptions.first.toARGB32();
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameFr.dispose();
    super.dispose();
  }

  String _kindLabel(CategoryKind kind, S s) => switch (kind) {
    CategoryKind.both => s.kindBoth,
    CategoryKind.expense => s.kindExpense,
    CategoryKind.income => s.kindIncome,
  };

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    if (_nameAr.text.trim().isEmpty) {
      setState(() => _error = s.fieldRequired(s.categoryName));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(categoryRepositoryProvider);
      if (_isEdit) {
        await repo.update(
          uid,
          widget.category!.copyWith(
            nameAr: _nameAr.text.trim(),
            nameFr: _nameFr.text.trim().isEmpty
                ? _nameAr.text.trim()
                : _nameFr.text.trim(),
            iconCode: _icon,
            colorValue: _color,
            kind: _kind,
          ),
        );
      } else {
        await repo.create(
          uid,
          Category(
            id: '',
            nameAr: _nameAr.text.trim(),
            nameFr: _nameFr.text.trim().isEmpty
                ? _nameAr.text.trim()
                : _nameFr.text.trim(),
            iconCode: _icon,
            colorValue: _color,
            kind: _kind,
          ),
        );
      }
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
    final category = widget.category;
    if (uid == null || category == null) return;

    final ok = await showConfirmDialog(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteCategoryConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(categoryRepositoryProvider).delete(uid, category.id);
      if (!mounted) return;
      showAppSnack(context, s.deletedDone);
      Navigator.of(context).pop();
    } catch (_) {
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
              _isEdit ? s.editCategory : s.addCategory,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameAr,
              label: '${s.categoryName} (ع)',
              prefixIcon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _nameFr,
              label: '${s.categoryName} (FR)',
              hint: s.optional,
              prefixIcon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<CategoryKind>(
              initialValue: _kind,
              decoration: InputDecoration(
                labelText: s.categoryKind,
                prefixIcon: const Icon(Icons.tune_rounded),
              ),
              items: [
                for (final kind in CategoryKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(_kindLabel(kind, s)),
                  ),
              ],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            const SizedBox(height: 18),
            Text(
              s.icon,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in DefaultData.iconOptions)
                  InkWell(
                    onTap: () => setState(() => _icon = icon.codePoint),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _icon == icon.codePoint
                            ? Color(_color).withValues(alpha: .22)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _icon == icon.codePoint
                              ? Color(_color)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 21,
                        color: _icon == icon.codePoint
                            ? Color(_color)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
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
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
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
