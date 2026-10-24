import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notifications_service.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../dart/presentation/dart_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../notifications/providers/reminders_provider.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../seasonal/presentation/seasonal_screen.dart';
import '../../subscriptions/presentation/subscriptions_screen.dart';
import '../providers/settings_providers.dart';
import 'my_data_section.dart';
import 'pay_period_setup_screen.dart';
import 'settings_widgets.dart';

/// Settings in four plain blocks: my salary, money tools, preferences,
/// and account & data.
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

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final s = ref.read(sProvider);
    if (enabled) {
      final granted = await NotificationsService.instance.requestPermission();
      if (granted == false) {
        if (context.mounted) {
          showAppSnack(context, s.notificationsDenied, error: true);
        }
        return;
      }
    }
    await setNotificationsEnabled(ref, enabled);
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final s = ref.read(sProvider);
    final picked = await showSettingsChoice<String>(
      context,
      title: s.language,
      selected: ref.read(localeProvider),
      choices: [
        SettingsChoice('ar', s.arabicLabel),
        const SettingsChoice('fr', 'Français'),
      ],
    );
    if (picked != null) await setLocale(ref, picked);
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final s = ref.read(sProvider);
    final current = switch (ref.read(appThemeModeProvider)) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    final picked = await showSettingsChoice<String>(
      context,
      title: s.theme,
      selected: current,
      choices: [
        SettingsChoice('system', s.themeSystem),
        SettingsChoice('light', s.themeLight),
        SettingsChoice('dark', s.themeDark),
      ],
    );
    if (picked != null) await setThemeMode(ref, picked);
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final s = ref.read(sProvider);
    final picked = await showSettingsChoice<String>(
      context,
      title: s.currencyDisplay,
      selected: ref.read(millionsModeProvider) ? 'millions' : 'dzd',
      choices: [
        SettingsChoice('dzd', s.currencyDzd),
        SettingsChoice(
          'millions',
          s.currencyMillions,
          hint: s.currencyDisplayHint,
        ),
      ],
    );
    if (picked != null) await setCurrencyDisplay(ref, picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsOrNullProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final millions = ref.watch(millionsModeProvider);
    final notificationsOn = ref.watch(notificationsEnabledProvider);

    final hasSalary = settings != null && settings.salary > 0;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Who is signed in.
          _ProfileHeader(
            name: settings?.displayName ?? '',
            email: settings?.email ?? '',
          ),
          const SizedBox(height: 20),

          // The numbers the whole app is built on.
          SettingsSection(
            title: s.mySalary,
            children: [
              SettingsTile(
                icon: Icons.payments_rounded,
                title: hasSalary ? formatDzd(settings.salary) : s.setUpSalary,
                subtitle: hasSalary ? s.paydayOfMonth(settings.payday) : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PayPeriodSetupScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Features, kept apart from the settings proper.
          _SectionLabel(s.moneyTools),
          const SizedBox(height: 8),
          _ToolsGrid(
            tools: [
              _Tool(
                Icons.autorenew_rounded,
                s.subscriptions,
                const Color(0xFF00897B),
                () => Navigator.of(context).push(SubscriptionsScreen.route()),
              ),
              _Tool(
                Icons.pie_chart_rounded,
                s.budgets,
                const Color(0xFFE65100),
                () => Navigator.of(context).push(BudgetsScreen.route()),
              ),
              _Tool(
                Icons.savings_rounded,
                s.toolGoals,
                const Color(0xFF1E88E5),
                () => Navigator.of(context).push(GoalsScreen.route()),
              ),
              _Tool(
                Icons.groups_rounded,
                s.dartGroups,
                const Color(0xFF6D4C9F),
                () => Navigator.of(context).push(DartScreen.route()),
              ),
              _Tool(
                Icons.event_available_rounded,
                s.toolSeasonal,
                const Color(0xFFC2185B),
                () => Navigator.of(context).push(SeasonalScreen.route()),
              ),
              _Tool(
                Icons.insights_rounded,
                s.reports,
                const Color(0xFF00873D),
                () => Navigator.of(context).push(ReportsScreen.route()),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // How the app looks and behaves.
          SettingsSection(
            title: s.preferences,
            children: [
              SettingsTile(
                icon: Icons.notifications_rounded,
                title: s.remindersToggle,
                subtitle: s.remindersHint,
                trailing: Switch(
                  value: notificationsOn,
                  onChanged: (v) => _toggleNotifications(context, ref, v),
                ),
                onTap: () =>
                    _toggleNotifications(context, ref, !notificationsOn),
              ),
              SettingsTile(
                icon: Icons.translate_rounded,
                title: s.language,
                value: locale == 'fr' ? 'Français' : s.arabicLabel,
                onTap: () => _pickLanguage(context, ref),
              ),
              SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: s.theme,
                value: switch (themeMode) {
                  ThemeMode.light => s.themeLight,
                  ThemeMode.dark => s.themeDark,
                  _ => s.themeSystem,
                },
                onTap: () => _pickTheme(context, ref),
              ),
              SettingsTile(
                icon: Icons.attach_money_rounded,
                title: s.currencyDisplay,
                value: millions ? s.currencyMillionsShort : s.currencyDzdShort,
                onTap: () => _pickCurrency(context, ref),
              ),
              SettingsTile(
                icon: Icons.category_rounded,
                title: s.categories,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Backup, sign out, delete: the account-wide actions, last.
          MyDataSection(onSignOut: () => _signOut(context, ref)),
          const SizedBox(height: 24),

          Text(
            s.aboutText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Tool {
  const _Tool(this.icon, this.label, this.color, this.onTap);

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Money features as rows of three tiles. Rows (not a fixed-ratio grid) so a
/// tile grows with large system fonts instead of clipping its label; tiles in
/// a row keep the same height.
class _ToolsGrid extends StatelessWidget {
  const _ToolsGrid({required this.tools});

  final List<_Tool> tools;

  static const int _perRow = 3;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_Tool>>[
      for (var i = 0; i < tools.length; i += _perRow)
        tools.sublist(i, (i + _perRow).clamp(0, tools.length)),
    ];
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _perRow; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: i < rows[r].length
                        ? _ToolTile(tool: rows[r][i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tool.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(tool.icon, color: tool.color, size: 23),
              ),
              const SizedBox(height: 8),
              Text(
                tool.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
