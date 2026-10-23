import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../models/user_settings.dart';

/// `users/{uid}` document (profile + settings).
final settingsProvider = StreamProvider<UserSettings?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<UserSettings?>.value(null);
  return ref.watch(settingsRepositoryProvider).watch(uid);
});

/// Current settings or a safe default while loading.
final settingsOrNullProvider = Provider<UserSettings?>(
  (ref) => ref.watch(settingsProvider).valueOrNull,
);

/// `true` when amounts are shown the Algerian way (`1.25 مليون`).
final millionsModeProvider = Provider<bool>(
  (ref) => ref.watch(settingsOrNullProvider)?.millionsMode ?? false,
);

final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(settingsOrNullProvider)?.themeModeName;
  return switch (mode) {
    ThemeModeName.light => ThemeMode.light,
    ThemeModeName.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// Whether the pay-period onboarding has been completed.
final setupCompletedProvider = Provider<bool>(
  (ref) => ref.watch(settingsOrNullProvider)?.setupCompleted ?? false,
);

/// Writes the chosen language to Firestore and applies it locally.
Future<void> setLocale(WidgetRef ref, String locale) async {
  ref.read(localeProvider.notifier).state = locale;
  final uid = ref.read(uidProvider);
  if (uid != null) {
    await ref.read(settingsRepositoryProvider).saveLocale(uid, locale);
  }
}

Future<void> setCurrencyDisplay(WidgetRef ref, String mode) async {
  final uid = ref.read(uidProvider);
  if (uid != null) {
    await ref.read(settingsRepositoryProvider).saveCurrencyDisplay(uid, mode);
  }
}

Future<void> setThemeMode(WidgetRef ref, String mode) async {
  final uid = ref.read(uidProvider);
  if (uid != null) {
    await ref.read(settingsRepositoryProvider).saveThemeMode(uid, mode);
  }
}

Future<void> setNotificationsEnabled(WidgetRef ref, bool enabled) async {
  final uid = ref.read(uidProvider);
  if (uid != null) {
    await ref
        .read(settingsRepositoryProvider)
        .saveNotificationsEnabled(uid, enabled);
  }
}
