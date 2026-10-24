// Renders the real settings screen (no Firebase): the four blocks appear in
// order, choosers open, and the layout holds in French and with large text.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/core/providers/core_providers.dart';
import 'package:masarifi/core/providers/ui_providers.dart';
import 'package:masarifi/core/theme/app_theme.dart';
import 'package:masarifi/features/settings/models/user_settings.dart';
import 'package:masarifi/features/settings/presentation/settings_screen.dart';
import 'package:masarifi/features/settings/providers/settings_providers.dart';

const settings = UserSettings(
  uid: 'u1',
  displayName: 'كريم مرابط',
  email: 'karim@example.com',
  salary: 60000,
  payday: 25,
);

Future<void> pumpSettings(
  WidgetTester tester, {
  String locale = 'ar',
  Size size = const Size(1080, 2400),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        uidProvider.overrideWithValue(null),
        localeProvider.overrideWith((ref) => locale),
        settingsOrNullProvider.overrideWithValue(settings),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(locale),
        supportedLocales: const [Locale('ar'), Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double topOf(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  testWidgets('four blocks, in order: salary, tools, preferences, account', (
    tester,
  ) async {
    await pumpSettings(tester, size: const Size(1080, 4800));
    expect(tester.takeException(), isNull);

    expect(find.text('كريم مرابط'), findsOneWidget);
    expect(find.text('يوم 25 من كل شهر'), findsOneWidget);

    final salary = topOf(tester, 'راتبي');
    final tools = topOf(tester, 'أدوات المال');
    final prefs = topOf(tester, 'التفضيلات');
    final account = topOf(tester, 'الحساب والبيانات');
    expect(salary, lessThan(tools));
    expect(tools, lessThan(prefs));
    expect(prefs, lessThan(account));

    // All six tools are in the grid.
    for (final tool in [
      'الاشتراكات',
      'الميزانيات',
      'الأهداف',
      'الدَّارات',
      'المواسم',
      'التقارير',
    ]) {
      expect(find.text(tool), findsOneWidget, reason: tool);
    }

    // Deleting the account is the very last row; sign out sits just above.
    expect(
      topOf(tester, 'تسجيل الخروج'),
      lessThan(topOf(tester, 'حذف حسابي نهائياً')),
    );
  });

  testWidgets('each preference shows its current value', (tester) async {
    await pumpSettings(tester, size: const Size(1080, 4800));
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('حسب النظام'), findsOneWidget);
    expect(find.text('بالدينار'), findsOneWidget);
  });

  testWidgets('tapping language opens a chooser with both languages', (
    tester,
  ) async {
    await pumpSettings(tester, size: const Size(1080, 4800));
    await tester.tap(find.text('اللغة'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Français'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('tapping appearance offers system, light and dark', (
    tester,
  ) async {
    await pumpSettings(tester, size: const Size(1080, 4800));
    await tester.tap(find.text('المظهر'));
    await tester.pumpAndSettle();
    expect(find.text('فاتح'), findsOneWidget);
    expect(find.text('داكن'), findsOneWidget);
  });

  testWidgets('French layout has no overflow', (tester) async {
    await pumpSettings(tester, locale: 'fr', size: const Size(1080, 4800));
    expect(tester.takeException(), isNull);
    expect(find.text('Préférences'), findsOneWidget);
  });

  testWidgets('small phone with large text has no overflow', (tester) async {
    await pumpSettings(tester, size: const Size(720, 4800), textScale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
