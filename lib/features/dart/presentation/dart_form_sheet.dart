import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../models/dart_group.dart';

/// Create or edit a dawra (members as comma-separated names).
class DartFormSheet extends ConsumerStatefulWidget {
  const DartFormSheet({super.key, this.group});

  final DartGroup? group;

  static Future<void> show(BuildContext context, {DartGroup? group}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DartFormSheet(group: group),
    );
  }

  @override
  ConsumerState<DartFormSheet> createState() => _DartFormSheetState();
}

class _DartFormSheetState extends ConsumerState<DartFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _members;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _name = TextEditingController(text: group?.name ?? '');
    _amount = TextEditingController(
      text: group == null ? '' : '${group.contributionAmount}',
    );
    _members = TextEditingController(text: group?.memberNames.join(', ') ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _members.dispose();
    super.dispose();
  }

  List<String> _parseMembers() => _members.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final nameError = validateName(s, _name.text, s.dartName);
    final amountText = _amount.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);
    final members = _parseMembers();

    if (nameError != null || amountError != null) {
      setState(() => _error = nameError ?? amountError);
      return;
    }
    if (members.length < 2) {
      setState(() => _error = s.dartMembersRequired);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final meName = _isEdit
        ? (members.contains(widget.group!.meName)
              ? widget.group!.meName
              : members.first)
        : members.first;

    try {
      if (_isEdit) {
        final updated = DartGroup(
          id: widget.group!.id,
          name: _name.text.trim(),
          contributionAmount: int.parse(amountText),
          memberNames: members,
          meName: meName,
          currentRound: widget.group!.currentRound,
          startDate: widget.group!.startDate,
          payments: widget.group!.payments,
          createdAt: widget.group!.createdAt,
        );
        await ref.read(dartRepositoryProvider).update(uid, updated);
      } else {
        final group = DartGroup(
          id: '',
          name: _name.text.trim(),
          contributionAmount: int.parse(amountText),
          memberNames: members,
          meName: meName,
          currentRound: 1,
          startDate: DateTime.now(),
        );
        await ref.read(dartRepositoryProvider).create(uid, group);
      }
      if (!mounted) return;
      showAppSnack(context, s.dartSaved);
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
      message: s.deleteDartConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(dartRepositoryProvider).delete(uid, widget.group!.id);
      if (!mounted) return;
      showAppSnack(context, s.dartDeleted);
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
              _isEdit ? s.editDart : s.addDart,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.dartPaymentsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: s.dartName,
              prefixIcon: Icons.groups_outlined,
              validator: (v) => validateName(s, v ?? '', s.dartName),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _amount,
              label: s.contributionAmount,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _members,
              label: s.members,
              hint: s.membersHint,
              prefixIcon: Icons.people_outline_rounded,
              maxLines: 2,
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
