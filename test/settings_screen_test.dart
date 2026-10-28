// Renders the real settings screens (no Firebase): headings only on the main
// page, each heading opens its details, and every page holds in French and
// with large text.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/core/providers/core_providers.dart';
import 'package:chehria/core/providers/ui_providers.dart';
import 'package:chehria/core/theme/app_theme.dart';
import 'package:chehria/features/settings/models/user_settings.dart';
import 'package:chehria/features/settings/presentation/settings_screen.dart';
import 'package:chehria/features/settings/providers/settings_providers.dart';

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

Future<void> openHeading(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

Future<void> goBack(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

const tools = [
  'الاشتراكات',
  'الميزانيات',
  'أهداف الادخار',
  'الدَّارات',
  'التخطيط الموسمي',
  'التقارير',
];

void main() {
  testWidgets('main page: profile, salary, three headings, sign out last', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('كريم مرابط'), findsOneWidget);
    // The salary is shown directly, not behind a heading.
    expect(find.text('يوم 25 من كل شهر'), findsOneWidget);

    final salary = topOf(tester, 'راتبي');
    final toolsTop = topOf(tester, 'أدوات المال');
    final prefs = topOf(tester, 'التفضيلات');
    final account = topOf(tester, 'الحساب والبيانات');
    final signOut = topOf(tester, 'تسجيل الخروج');
    expect(salary, lessThan(toolsTop));
    expect(toolsTop, lessThan(prefs));
    expect(prefs, lessThan(account));
    expect(account, lessThan(signOut));

    // Headings only: no tool, preference or delete row on this page.
    for (final tool in tools) {
      expect(find.text(tool), findsNothing, reason: tool);
    }
    expect(find.text('اللغة'), findsNothing);
    expect(find.text('حذف حسابي نهائياً'), findsNothing);

    // Everything fits on one phone screen, sign out included.
    expect(
      tester.getBottomLeft(find.text('تسجيل الخروج')).dy,
      lessThan(2400 / 2.625),
    );
  });

  testWidgets('money tools lists the six tools vertically, one per row', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openHeading(tester, 'أدوات المال');
    expect(tester.takeException(), isNull);

    var previousTop = -1.0;
    final x = <double>{};
    for (final tool in tools) {
      expect(find.text(tool), findsOneWidget, reason: tool);
      final top = topOf(tester, tool);
      expect(top, greaterThan(previousTop), reason: '$tool below the previous');
      previousTop = top;
      x.add(tester.getTopRight(find.text(tool)).dx.roundToDouble());
    }
    // Same column: every title starts at the same edge.
    expect(x, hasLength(1));
    // Each row explains what the tool is for.
    expect(find.text('سقف شهري لمصاريف كل فئة'), findsOneWidget);
  });

  testWidgets('preferences opens rows with their current values', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openHeading(tester, 'التفضيلات');
    expect(tester.takeException(), isNull);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('حسب النظام'), findsOneWidget);
    expect(find.text('بالدينار'), findsOneWidget);
    expect(find.text('تذكيرات الاستحقاقات'), findsOneWidget);
  });

  testWidgets('language and appearance choosers open', (tester) async {
    await pumpSettings(tester);
    await openHeading(tester, 'التفضيلات');

    await tester.tap(find.text('اللغة'));
    await tester.pumpAndSettle();
    expect(find.text('Français'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    Navigator.of(tester.element(find.text('Français'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('المظهر'));
    await tester.pumpAndSettle();
    expect(find.text('فاتح'), findsOneWidget);
    expect(find.text('داكن'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account & data opens backup and delete', (tester) async {
    await pumpSettings(tester);
    await openHeading(tester, 'الحساب والبيانات');
    expect(tester.takeException(), isNull);
    expect(find.text('تصدير نسخة احتياطية'), findsOneWidget);
    expect(find.text('حذف حسابي نهائياً'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsNothing);
  });

  testWidgets('French works on every page', (tester) async {
    await pumpSettings(tester, locale: 'fr');
    expect(tester.takeException(), isNull);
    for (final heading in ['Outils', 'Préférences', 'Compte et données']) {
      await openHeading(tester, heading);
      expect(tester.takeException(), isNull, reason: heading);
      await goBack(tester);
    }
  });

  testWidgets('small phone with large text: no overflow on any page', (
    tester,
  ) async {
    await pumpSettings(tester, size: const Size(720, 2400), textScale: 1.3);
    expect(tester.takeException(), isNull);
    for (final heading in ['أدوات المال', 'التفضيلات', 'الحساب والبيانات']) {
      await openHeading(tester, heading);
      expect(tester.takeException(), isNull, reason: heading);
      await goBack(tester);
    }
  });
}
