import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/errors/error_reporter.dart';
import 'core/localization/s_context.dart';
import 'core/providers/core_providers.dart';
import 'core/providers/ui_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/notifications/providers/reminders_provider.dart';
import 'features/settings/providers/settings_providers.dart';

/// Root widget: theme, locale and the auth gate.
class ChehriaApp extends ConsumerStatefulWidget {
  const ChehriaApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  ConsumerState<ChehriaApp> createState() => _ChehriaAppState();
}

class _ChehriaAppState extends ConsumerState<ChehriaApp> {
  Timer? _midnight;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The dashboard depends on "today": roll it over at midnight and when the
    // app comes back to the foreground on another day.
    _lifecycle = AppLifecycleListener(onResume: _refreshToday);
    _scheduleMidnight();
    if (widget.firebaseReady) {
      ref.listenManual<String?>(
        uidProvider,
        (_, uid) => setErrorReportingUser(uid),
        fireImmediately: true,
      );
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    // A few seconds of margin so the new day has surely started.
    _midnight = Timer(next.difference(now) + const Duration(seconds: 5), () {
      _refreshToday();
      _scheduleMidnight();
    });
  }

  /// Updates [nowProvider] only when the calendar day changed, so the
  /// Firestore queries that depend on it are not rebuilt for nothing.
  void _refreshToday() {
    final current = ref.read(nowProvider);
    final now = DateTime.now();
    final sameDay =
        current.year == now.year &&
        current.month == now.month &&
        current.day == now.day;
    if (!sameDay) ref.read(nowProvider.notifier).state = now;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = widget.firebaseReady;
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
