import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/localization/s.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../debts/models/debt.dart';
import '../../debts/providers/debts_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../subscriptions/models/subscription.dart';
import '../../subscriptions/providers/subscriptions_providers.dart';
import '../domain/reminder_planner.dart';

/// Whether the user switched the local reminders on in settings.
final notificationsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(settingsOrNullProvider)?.notificationsEnabled ?? false,
);

/// Everything the reminder planner needs, in one value.
class ReminderInputs {
  const ReminderInputs({
    required this.enabled,
    required this.s,
    required this.payday,
    required this.subscriptions,
    required this.debts,
    required this.now,
  });

  final bool enabled;
  final S s;
  final int payday;
  final List<Subscription> subscriptions;
  final List<Debt> debts;
  final DateTime now;
}

final reminderInputsProvider = Provider<ReminderInputs>((ref) {
  return ReminderInputs(
    enabled: ref.watch(notificationsEnabledProvider),
    s: ref.watch(sProvider),
    payday: ref.watch(settingsOrNullProvider)?.payday ?? 1,
    subscriptions: ref.watch(subscriptionsOrNullProvider),
    debts: ref.watch(debtsOrNullProvider),
    now: ref.watch(nowProvider),
  );
});

/// Keeps the scheduled notifications in sync with the data.
///
/// Watched once from the app root; every change of the inputs re-schedules.
final reminderSyncProvider = Provider<void>((ref) {
  ref.listen<ReminderInputs>(
    reminderInputsProvider,
    // Scheduled on a microtask so the plugin is never called mid-build.
    (_, _) => Future.microtask(() => syncReminders(ref)),
    fireImmediately: true,
  );
});

Future<void> syncReminders(Ref ref) async {
  final inputs = ref.read(reminderInputsProvider);
  final service = NotificationsService.instance;
  try {
    if (!inputs.enabled) {
      await service.cancelAll();
      return;
    }
    await service.init();
    await service.sync(
      buildReminders(
        now: inputs.now,
        s: inputs.s,
        payday: inputs.payday,
        subscriptions: inputs.subscriptions,
        debts: inputs.debts,
      ),
      channelName: inputs.s.reminderChannelName,
      channelDescription: inputs.s.reminderChannelDescription,
    );
  } catch (e, st) {
    reportError(e, st, reason: 'reminders_provider');
    // Reminders are a convenience: never break the app over them.
  }
}
