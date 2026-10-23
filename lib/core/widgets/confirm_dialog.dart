import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ui_providers.dart';

/// `true` when the user confirmed the action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = true,
}) async {
  final s = ProviderScope.containerOf(context, listen: false).read(sProvider);
  final theme = Theme.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? s.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  minimumSize: const Size(96, 44),
                )
              : FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? s.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Floating snackbar with a success/error look.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? theme.colorScheme.error : null,
      ),
    );
}
