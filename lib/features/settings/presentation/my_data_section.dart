import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'settings_widgets.dart';

/// JSON backup and permanent account deletion (last, in red).
class MyDataSection extends ConsumerWidget {
  const MyDataSection({super.key});

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    try {
      final json = await ref.read(userDataRepositoryProvider).exportJson(uid);
      final now = DateTime.now();
      final day =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(json)),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: ['chehria-backup-$day.json'],
          title: s.exportBackup,
        ),
      );
    } catch (e, st) {
      reportError(e, st, reason: 'backup export');
      if (context.mounted) showAppSnack(context, s.exportFailed, error: true);
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    final auth = ref.read(authRepositoryProvider);

    final ok = await showConfirmDialog(
      context,
      title: s.deleteUserAccount,
      message: s.deleteUserAccountConfirm,
      confirmLabel: s.delete,
    );
    if (!ok || !context.mounted) return;

    String? password;
    if (auth.usesPassword) {
      password = await _askPassword(context, s.confirmWithPassword);
      if (password == null || password.isEmpty || !context.mounted) return;
    }

    // Identity first: if it fails nothing has been deleted yet.
    try {
      await auth.reauthenticate(password: password);
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, authErrorMessage(e, s), error: true);
      }
      return;
    }
    if (!context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(s.deletingAccount)),
          ],
        ),
      ),
    );

    try {
      await NotificationsService.instance.cancelAll();
      // Data before the auth user: the security rules need it to exist.
      await ref.read(userDataRepositoryProvider).deleteAll(uid);
      await auth.deleteUser();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(s.accountDeleted)));
    } catch (e, st) {
      reportError(e, st, reason: 'account deletion');
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(e, s))));
    }
  }

  Future<String?> _askPassword(BuildContext context, String title) {
    final controller = TextEditingController();
    final s = ProviderScope.containerOf(context, listen: false).read(sProvider);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: s.password),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(s.confirm),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);

    return SettingsSection(
      title: s.myData,
      children: [
        SettingsTile(
          icon: Icons.download_rounded,
          title: s.exportBackup,
          subtitle: s.exportBackupHint,
          onTap: () => _exportBackup(context, ref),
        ),
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          title: s.deleteUserAccount,
          subtitle: s.deleteUserAccountHint,
          destructive: true,
          onTap: () => _deleteAccount(context, ref),
        ),
      ],
    );
  }
}
