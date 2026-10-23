import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notifications_service.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
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
import 'pay_period_setup_screen.dart';

/// Profile, pay period, display options and app preferences.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsOrNullProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final millions = ref.watch(millionsModeProvider);
    final notificationsOn = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ------------------------------------------------------- profile
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                (settings?.displayName.isNotEmpty ?? false)
                    ? settings!.displayName
                    : (settings?.email.isNotEmpty ?? false)
                    ? settings!.email
                    : s.profile,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(settings?.email ?? ''),
            ),
          ),
          const SizedBox(height: 16),

          // -------------------------------------------------- salary block
          Text(
            s.salaryAndPayday,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(s.monthlySalary),
                  trailing: Text(
                    settings == null || settings.salary <= 0
                        ? '—'
                        : '${settings.salary} دج',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(s.payday),
                  trailing: Text(
                    settings == null
                        ? '—'
                        : '${settings.payday} ${s.paydayValue}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(s.edit),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PayPeriodSetupScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ----------------------------------------------------- display
          Text(
            s.currencyDisplay,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'dzd', label: Text(s.currencyDzd)),
                  ButtonSegment(
                    value: 'millions',
                    label: Text(s.currencyMillions),
                  ),
                ],
                selected: {millions ? 'millions' : 'dzd'},
                onSelectionChanged: (v) => setCurrencyDisplay(ref, v.first),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.currencyDisplayHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // ---------------------------------------------------- language
          Text(
            s.language,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'ar', label: Text(s.arabicLabel)),
                  const ButtonSegment(value: 'fr', label: Text('Français')),
                ],
                selected: {locale},
                onSelectionChanged: (v) => setLocale(ref, v.first),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------ theme
          Text(
            s.theme,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'system', label: Text(s.themeSystem)),
                  ButtonSegment(value: 'light', label: Text(s.themeLight)),
                  ButtonSegment(value: 'dark', label: Text(s.themeDark)),
                ],
                selected: {
                  switch (themeMode) {
                    ThemeMode.light => 'light',
                    ThemeMode.dark => 'dark',
                    _ => 'system',
                  },
                },
                onSelectionChanged: (v) => setThemeMode(ref, v.first),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------ reminders
          Text(
            s.notifications,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(s.remindersToggle),
              subtitle: Text(
                s.remindersHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: notificationsOn,
              onChanged: (v) => _toggleNotifications(context, ref, v),
            ),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------ more
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.autorenew_rounded),
                  title: Text(s.subscriptions),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.of(context).push(SubscriptionsScreen.route()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: Text(s.budgets),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.of(context).push(BudgetsScreen.route()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(s.goals),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(GoalsScreen.route()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: Text(s.dartGroups),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(DartScreen.route()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.beach_access_outlined),
                  title: Text(s.seasonal),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.of(context).push(SeasonalScreen.route()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: Text(s.reports),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.of(context).push(ReportsScreen.route()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(s.categories),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(s.signOut),
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ----------------------------------------------------- about
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.about,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.aboutText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
