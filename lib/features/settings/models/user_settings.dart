import 'package:cloud_firestore/cloud_firestore.dart';

/// Profile + settings stored in `users/{uid}`.
class UserSettings {
  const UserSettings({
    required this.uid,
    this.displayName = '',
    this.email = '',
    this.salary = 0,
    this.payday = 1,
    this.locale = 'ar',
    this.currencyDisplay = 'dzd',
    this.themeMode = 'system',
    this.notificationsEnabled = false,
    this.setupCompleted = false,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;

  /// Monthly net salary in **dinars (integer)**.
  final int salary;

  /// Day of month 1-31 (clamped to the last day of shorter months).
  final int payday;

  /// `'ar'` or `'fr'`.
  final String locale;

  /// `'dzd'` (`12,500 دج`) or `'millions'` (`1.25 مليون`).
  final String currencyDisplay;

  /// `'system'`, `'light'` or `'dark'`.
  final String themeMode;

  /// Local reminders for bills, debts and the pay day.
  final bool notificationsEnabled;

  /// True once the pay-period onboarding has been completed.
  final bool setupCompleted;

  final DateTime? createdAt;

  bool get millionsMode => currencyDisplay == 'millions';

  ThemeModeName get themeModeName => switch (themeMode) {
    'light' => ThemeModeName.light,
    'dark' => ThemeModeName.dark,
    _ => ThemeModeName.system,
  };

  UserSettings copyWith({
    String? displayName,
    String? email,
    int? salary,
    int? payday,
    String? locale,
    String? currencyDisplay,
    String? themeMode,
    bool? notificationsEnabled,
    bool? setupCompleted,
  }) {
    return UserSettings(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      salary: salary ?? this.salary,
      payday: payday ?? this.payday,
      locale: locale ?? this.locale,
      currencyDisplay: currencyDisplay ?? this.currencyDisplay,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      createdAt: createdAt,
    );
  }

  factory UserSettings.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return UserSettings(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      salary: (d['salary'] as num?)?.toInt() ?? 0,
      payday: (d['payday'] as num?)?.toInt() ?? 1,
      locale: d['locale'] as String? ?? 'ar',
      currencyDisplay: d['currencyDisplay'] as String? ?? 'dzd',
      themeMode: d['themeMode'] as String? ?? 'system',
      notificationsEnabled: d['notificationsEnabled'] as bool? ?? false,
      setupCompleted: d['setupCompleted'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'email': email,
    'salary': salary,
    'payday': payday,
    'locale': locale,
    'currencyDisplay': currencyDisplay,
    'themeMode': themeMode,
    'notificationsEnabled': notificationsEnabled,
    'setupCompleted': setupCompleted,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

enum ThemeModeName { system, light, dark }
