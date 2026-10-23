import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/s_context.dart';
import 'core/providers/ui_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/notifications/providers/reminders_provider.dart';
import 'features/settings/providers/settings_providers.dart';

/// Root widget: theme, locale and the auth gate.
class MasarifiApp extends ConsumerWidget {
  const MasarifiApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final s = ref.watch(sProvider);
    final settings = ref.watch(settingsOrNullProvider);

    // Apply the language saved in Firestore.
    if (settings != null && settings.locale != localeCode) {
      Future.microtask(
        () => ref.read(localeProvider.notifier).state = settings.locale,
      );
    }

    // Keeps the local reminders in sync with subscriptions, debts and payday.
    if (firebaseReady) ref.watch(reminderSyncProvider);

    return MaterialApp(
      title: s.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: Locale(localeCode),
      supportedLocales: const [Locale('ar'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: firebaseReady ? const AuthGate() : const SetupRequiredScreen(),
    );
  }
}

/// Shown until `flutterfire configure` has been executed.
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.rocket_launch_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                s.setupRequiredTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.setupRequiredBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
