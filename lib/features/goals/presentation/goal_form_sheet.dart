import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../models/goal.dart';

/// Create or edit a savings goal.
class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({
    super.key,
    this.goal,
    this.initialName,
    this.initialDeadline,
    this.initialKind,
    this.initialEventId,
  });

  final Goal? goal;
  final String? initialName;
  final DateTime? initialDeadline;
  final GoalKind? initialKind;
  final String? initialEventId;

  static Future<void> show(
    BuildContext context, {
    Goal? goal,
    String? initialName,
    DateTime? initialDeadline,
    GoalKind? initialKind,
    String? initialEventId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GoalFormSheet(
        goal: goal,
        initialName: initialName,
        initialDeadline: initialDeadline,
        initialKind: initialKind,
        initialEventId: initialEventId,
      ),
    );
  }

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _note;
  DateTime? _deadline;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _name = TextEditingController(text: goal?.name ?? widget.initialName ?? '');
    _target = TextEditingController(
      text: goal == null ? '' : '${goal.targetAmount}',
    );
    _note = TextEditingController(text: goal?.note ?? '');
    _deadline = goal?.deadline ?? widget.initialDeadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final nameError = validateName(s, _name.text, s.goalName);
    final targetText = _target.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final targetError = validateAmount(s, targetText);

    if (nameError != null || targetError != null) {
      setState(() => _error = nameError ?? targetError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final target = int.parse(targetText);

    try {
      if (_isEdit) {
        final updated = Goal(
          id: widget.goal!.id,
          name: _name.text.trim(),
          targetAmount: target,
          savedAmount: widget.goal!.savedAmount,
          deadline: _deadline,
          note: _note.text.trim(),
          kind: widget.goal!.kind,
          eventId: widget.goal!.eventId,
          entries: widget.goal!.entries,
          createdAt: widget.goal!.createdAt,
        );
        await ref.read(goalRepositoryProvider).update(uid, updated);
      } else {
        final goal = Goal(
          id: '',
          name: _name.text.trim(),
          targetAmount: target,
          savedAmount: 0,
          deadline: _deadline,
          note: _note.text.trim(),
          kind: widget.initialKind ?? GoalKind.saving,
          eventId: widget.initialEventId,
        );
        await ref.read(goalRepositoryProvider).create(uid, goal);
      }
      if (!mounted) return;
      showAppSnack(context, s.goalSaved);
      Navigator.of(context).pop();
    } catch (e, st) {
      reportError(e, st, reason: 'goal_form_sheet');
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
      message: s.deleteGoalConfirm,
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(goalRepositoryProvider).delete(uid, widget.goal!.id);
      if (!mounted) return;
      showAppSnack(context, s.goalDeleted);
      Navigator.of(context).pop();
    } catch (e, st) {
      reportError(e, st, reason: 'goal_form_sheet');
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
              _isEdit ? s.editGoal : s.addGoal,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: s.goalName,
              prefixIcon: Icons.flag_outlined,
              validator: (v) => validateName(s, v ?? '', s.goalName),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _target,
              label: s.targetAmount,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(s.goalDeadline),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_deadline != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _deadline = null),
                    ),
                  Text(
                    _deadline == null
                        ? s.optional
                        : '${_deadline!.day.toString().padLeft(2, '0')}/'
                              '${_deadline!.month.toString().padLeft(2, '0')}/'
                              '${_deadline!.year}',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            AppTextField(
              controller: _note,
              label: s.note,
              hint: s.notePlaceholder,
              prefixIcon: Icons.notes_rounded,
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
