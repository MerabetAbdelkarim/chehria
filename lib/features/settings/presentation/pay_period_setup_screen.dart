import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../settings/providers/settings_providers.dart';

/// Onboarding (and later, editing) of salary + pay day + display options.
class PayPeriodSetupScreen extends ConsumerStatefulWidget {
  const PayPeriodSetupScreen({super.key, this.firstRun = false});

  /// `true` during first run: no back button, closes straight into the app.
  final bool firstRun;

  @override
  ConsumerState<PayPeriodSetupScreen> createState() =>
      _PayPeriodSetupScreenState();
}

class _PayPeriodSetupScreenState extends ConsumerState<PayPeriodSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _salary;
  late final TextEditingController _payday;

  bool _loading = false;
  String? _error;
  String _currencyMode = 'dzd';
  String _locale = 'ar';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsOrNullProvider);
    _salary = TextEditingController(
      text: settings != null && settings.salary > 0
          ? settings.salary.toString()
          : '',
    );
    _payday = TextEditingController(text: (settings?.payday ?? 1).toString());
    _currencyMode = settings?.currencyDisplay ?? 'dzd';
    _locale = settings?.locale ?? 'ar';
  }

  @override
  void dispose() {
    _salary.dispose();
    _payday.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final s = ref.read(sProvider);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = ref.read(uidProvider);
      if (uid == null) throw Exception(s.errorGeneric);
      final salary = int.parse(
        _salary.text.trim().replaceAll(RegExp(r'[^\d]'), ''),
      );
      final payday = int.parse(_payday.text.trim());

      await ref
          .read(settingsRepositoryProvider)
          .savePayPeriod(uid: uid, salary: salary, payday: payday);
      await ref
          .read(settingsRepositoryProvider)
          .saveCurrencyDisplay(uid, _currencyMode);
      await ref.read(settingsRepositoryProvider).saveLocale(uid, _locale);
      ref.read(localeProvider.notifier).state = _locale;

      if (!mounted) return;
      showAppSnack(context, s.savedDone);
      if (!widget.firstRun) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = s.errorGeneric);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.firstRun ? null : AppBar(title: Text(s.setupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.firstRun) ...[
                    Icon(
                      Icons.savings_rounded,
                      size: 60,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.setupTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    s.setupSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 26),
                  AppTextField(
                    controller: _salary,
                    label: s.monthlySalary,
                    hint: s.monthlySalaryHint,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.payments_rounded,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s,]')),
                    ],
                    validator: (v) => validateAmount(
                      s,
                      v?.replaceAll(RegExp(r'[^\d]'), '') ?? '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _payday,
                    label: s.payday,
                    hint: s.paydayHint,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.event_rounded,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => validatePayday(s, v ?? ''),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.paydayHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.currencyDisplay,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'dzd', label: Text(s.currencyDzd)),
                      ButtonSegment(
                        value: 'millions',
                        label: Text(s.currencyMillions),
                      ),
                    ],
                    selected: {_currencyMode},
                    onSelectionChanged: (v) =>
                        setState(() => _currencyMode = v.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.currencyDisplayHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.language,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'ar', label: Text(s.arabicLabel)),
                      ButtonSegment(value: 'fr', label: Text('Français')),
                    ],
                    selected: {_locale},
                    onSelectionChanged: (v) =>
                        setState(() => _locale = v.first),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(
                            widget.firstRun ? s.setupContinue : s.saveChanges,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
