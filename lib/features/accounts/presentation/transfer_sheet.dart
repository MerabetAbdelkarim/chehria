import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../providers/accounts_providers.dart';

/// Move money between two of the user's own accounts.
class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TransferSheet(),
    );
  }

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amount = TextEditingController();
  String? _fromId;
  String? _toId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sProvider);
    final uid = ref.read(uidProvider);
    final accounts = ref.read(accountsOrNullProvider);
    if (uid == null) return;

    final amountText = _amount.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final amountError = validateAmount(s, amountText);
    if (amountError != null) {
      setState(() => _error = amountError);
      return;
    }

    final fromId = _fromId ?? accounts.first.id;
    final toId =
        _toId ??
        (accounts.length > 1
            ? accounts.firstWhere((a) => a.id != fromId).id
            : fromId);

    if (fromId == toId) {
      setState(() => _error = s.transferTo);
      return;
    }

    final amount = int.parse(amountText);
    final from = accounts.firstWhere((a) => a.id == fromId);
    if (amount > from.balance) {
      setState(() => _error = s.insufficientBalance);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(accountRepositoryProvider)
          .transfer(uid: uid, fromId: fromId, toId: toId, amount: amount);
      if (!mounted) return;
      showAppSnack(context, s.transferDone);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = s.errorGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsOrNullProvider);

    if (accounts.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyBox(message: s.noAccounts),
      );
    }

    _fromId ??= accounts.first.id;
    _toId ??= accounts.firstWhere((a) => a.id != accounts.first.id).id;

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
              s.transfer,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _fromId,
              decoration: InputDecoration(
                labelText: s.transferFrom,
                prefixIcon: const Icon(Icons.logout_rounded),
              ),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _fromId = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _toId,
              decoration: InputDecoration(
                labelText: s.transferTo,
                prefixIcon: const Icon(Icons.login_rounded),
              ),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _toId = v),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _amount,
              label: s.transferAmount,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
              validator: (v) =>
                  validateAmount(s, v?.replaceAll(RegExp(r'[^\d]'), '') ?? ''),
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
                  : Text(s.transfer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal centered message used inside sheets.
class EmptyBox extends StatelessWidget {
  const EmptyBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
  );
}
