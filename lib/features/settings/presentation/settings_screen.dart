import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../providers/settings_providers.dart';
import 'account_data_screen.dart';
import 'money_tools_screen.dart';
import 'pay_period_setup_screen.dart';
import 'preferences_screen.dart';
import 'settings_widgets.dart';

/// Settings home: who is signed in, the salary (shown directly, it drives the
/// whole app), then three headings that each open their own page, and sign
/// out at the very bottom.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final s = ref.read(sProvider);
    final ok = await showConfirmDialog(
      context,
      title: s.signOut,
      message: s.signOutConfirm,
      destructive: false,
    );
    if (!ok || !context.mounted) return;
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsOrNullProvider);
    final hasSalary = settings != null && settings.salary > 0;
    void open(Route<void> route) => Navigator.of(context).push(route);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ProfileHeader(
            name: settings?.displayName ?? '',
            email: settings?.email ?? '',
          ),
          const SizedBox(height: 20),

          // Shown directly: the numbers the whole app is built on.
          SettingsSection(
            title: s.mySalary,
            children: [
              SettingsTile(
                icon: Icons.payments_rounded,
                title: hasSalary ? formatDzd(settings.salary) : s.setUpSalary,
                subtitle: hasSalary ? s.paydayOfMonth(settings.payday) : null,
                onTap: () => open(
                  MaterialPageRoute(
                    builder: (_) => const PayPeriodSetupScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Headings only; the details live on their own pages.
          SettingsSection(
            title: s.settings,
            children: [
              SettingsTile(
                icon: Icons.grid_view_rounded,
                color: const Color(0xFF00897B),
                title: s.moneyTools,
                subtitle: s.moneyToolsHint,
                onTap: () => open(MoneyToolsScreen.route()),
              ),
              SettingsTile(
                icon: Icons.tune_rounded,
                color: const Color(0xFF1E88E5),
                title: s.preferences,
                subtitle: s.preferencesHint,
                onTap: () => open(PreferencesScreen.route()),
              ),
              SettingsTile(
                icon: Icons.shield_outlined,
                color: const Color(0xFF6D4C9F),
                title: s.accountAndData,
                subtitle: s.accountAndDataHint,
                onTap: () => open(AccountDataScreen.route()),
              ),
            ],
          ),
          const SizedBox(height: 28),

          OutlinedButton.icon(
            onPressed: () => _signOut(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: .5)),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              s.signOut,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.aboutText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = name.isNotEmpty ? name : email;
    final initial = title.isNotEmpty
        ? title.characters.first.toUpperCase()
        : '';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: scheme.primaryContainer,
          child: initial.isEmpty
              ? Icon(Icons.person_rounded, color: scheme.onPrimaryContainer)
              : Text(
                  initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (name.isNotEmpty && email.isNotEmpty)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
