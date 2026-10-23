import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../settings/providers/settings_providers.dart';
import '../../settings/presentation/pay_period_setup_screen.dart';
import '../../shell/presentation/app_shell.dart';
import '../providers/auth_providers.dart';
import 'sign_in_screen.dart';

/// Decides which top-level screen to show:
/// splash -> sign-in -> profile bootstrap -> pay-period setup -> app shell.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  Widget _splash(String label) => Scaffold(body: LoadingView(label: label));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);

    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return _splash(s.checkingSession);
    if (auth.hasError) {
      return Scaffold(
        body: ErrorView(
          message: s.errorGeneric,
          onRetry: () => ref.invalidate(authStateProvider),
        ),
      );
    }

    if (auth.valueOrNull == null) return const SignInScreen();

    final profile = ref.watch(ensureProfileProvider);
    if (profile.isLoading) return _splash(s.loading);
    if (profile.hasError) {
      return Scaffold(
        body: ErrorView(
          message: s.errorGeneric,
          onRetry: () => ref.invalidate(ensureProfileProvider),
        ),
      );
    }

    final settings = ref.watch(settingsProvider);
    if (settings.isLoading) return _splash(s.loading);
    if (settings.hasError) {
      return Scaffold(
        body: ErrorView(
          message: s.errorGeneric,
          onRetry: () => ref.invalidate(settingsProvider),
        ),
      );
    }

    final userSettings = settings.valueOrNull;
    if (userSettings == null || !userSettings.setupCompleted) {
      return const PayPeriodSetupScreen(firstRun: true);
    }
    return const AppShell();
  }
}
