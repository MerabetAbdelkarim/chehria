import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../data/category_repository.dart';
import '../models/category.dart';

/// Deletes [category] after the safety checks and a confirmation.
///
/// Returns `true` when the category was deleted. Shared by the list screen
/// and the edit sheet so both apply the same rules.
Future<bool> confirmAndDeleteCategory(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final s = ref.read(sProvider);
  final uid = ref.read(uidProvider);
  if (uid == null) return false;

  if (CategoryRepository.isSystem(category.id)) {
    showAppSnack(context, s.categorySystemLocked, error: true);
    return false;
  }

  final repo = ref.read(categoryRepositoryProvider);
  try {
    if (await repo.isInUse(uid, category.id)) {
      if (context.mounted) showAppSnack(context, s.categoryInUse, error: true);
      return false;
    }
  } catch (e, st) {
    reportError(e, st, reason: 'category isInUse');
    if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    return false;
  }
  if (!context.mounted) return false;

  final ok = await showConfirmDialog(
    context,
    title: s.deleteConfirmTitle,
    message: s.deleteCategoryConfirm,
  );
  if (!ok || !context.mounted) return false;

  try {
    await repo.delete(uid, category.id);
    if (context.mounted) showAppSnack(context, s.deletedDone);
    return true;
  } catch (e, st) {
    reportError(e, st, reason: 'category delete');
    if (context.mounted) showAppSnack(context, s.errorGeneric, error: true);
    return false;
  }
}
