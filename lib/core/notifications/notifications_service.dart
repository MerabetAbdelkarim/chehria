import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// A local reminder ready to be scheduled.
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
  });

  /// Stable, non-negative id (derived from a key string).
  final int id;
  final String title;
  final String body;
  final DateTime fireAt;

  /// Deterministic id so the same reminder can be cancelled and rescheduled.
  static int stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

/// Thin wrapper around `flutter_local_notifications`.
///
/// The plugin needs the device time zone database; we sidestep it with a
/// fixed-offset location built from the device (Algeria has no DST, so a
/// single offset is always correct).
class NotificationsService {
  NotificationsService._();

  static final NotificationsService instance = NotificationsService._();

  static const String channelId = 'masarifi_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  tz.Location? _location;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    _location = _fixedOffset(DateTime.now().timeZoneOffset);
    tz.setLocalLocation(_location!);
    _initialized = true;
  }

  /// Asks the OS for the notification permission (Android 13+, iOS).
  /// Returns `null` on platforms that do not need it.
  Future<bool?> requestPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    await init();
    if (Platform.isAndroid) {
      return _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    return _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  /// Cancels everything and schedules [reminders] again.
  Future<void> sync(List<Reminder> reminders) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final reminder in reminders) {
      if (!reminder.fireAt.isAfter(now)) continue;
      await _schedule(reminder);
    }
  }

  Future<void> _schedule(Reminder reminder) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'التذكيرات',
        channelDescription: 'تذكيرات باستحقاقات الاشتراكات والديون ويوم الراتب',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      reminder.id,
      reminder.title,
      reminder.body,
      tz.TZDateTime.from(reminder.fireAt, _location!),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// A fixed-offset zone matching the device (no DST in Algeria).
  tz.Location _fixedOffset(Duration offset) {
    final minutes = offset.inMinutes;
    final label = 'GMT${minutes >= 0 ? '+' : ''}${minutes ~/ 60}';
    return tz.Location(label, const [tz.minTime], const [0], [
      tz.TimeZone(minutes * 60 * 1000, isDst: false, abbreviation: label),
    ]);
  }
}
