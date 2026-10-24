import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notifications_service.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../notifications/providers/reminders_provider.dart';
import '../providers/settings_providers.dart';
import 'settings_widgets.dart';

/// "Preferences": reminders, language, appearance, amount display and
/// categories. Each row shows its current value and opens a short chooser.
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const PreferencesScreen());

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
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final millions = ref.watch(millionsModeProvider);
    final notificationsOn = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.preferences)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SettingsSection(
            title: s.notifications,
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
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: s.languageAndDisplay,
            children: [
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
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: s.organizeOperations,
            children: [
              SettingsTile(
                icon: Icons.category_rounded,
                title: s.categories,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
