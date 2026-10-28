// Renders the real home screen with sample data (no Firebase): every state
// must lay out without overflow or exceptions, in Arabic and French.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/core/constants/default_data.dart';
import 'package:chehria/core/providers/core_providers.dart';
import 'package:chehria/core/providers/ui_providers.dart';
import 'package:chehria/core/theme/app_theme.dart';
import 'package:chehria/features/budgets/models/budget.dart';
import 'package:chehria/features/budgets/providers/budgets_providers.dart';
import 'package:chehria/features/categories/providers/categories_providers.dart';
import 'package:chehria/features/dashboard/domain/dashboard_calculator.dart';
import 'package:chehria/features/dashboard/presentation/dashboard_screen.dart';
import 'package:chehria/features/dashboard/providers/dashboard_providers.dart';
import 'package:chehria/features/dashboard/providers/home_providers.dart';
import 'package:chehria/features/debts/models/debt.dart';
import 'package:chehria/features/goals/models/goal.dart';
import 'package:chehria/features/goals/providers/goals_providers.dart';
import 'package:chehria/features/settings/models/user_settings.dart';
import 'package:chehria/features/subscriptions/domain/subscription_calculator.dart';
import 'package:chehria/features/subscriptions/models/subscription.dart';
import 'package:chehria/features/transactions/models/money_transaction.dart';
import 'package:chehria/features/transactions/providers/transactions_providers.dart';

final now = DateTime(2026, 10, 12, 18);
const settings = UserSettings(uid: 'u1', salary: 60000, payday: 1);

MoneyTransaction spend(int amount, DateTime date, String category) =>
    MoneyTransaction(
      id: 't$amount${date.day}',
      type: TxnType.expense,
      amount: amount,
      date: date,
      categoryId: category,
      accountId: 'acc_cash',
    );

final sampleTxns = [
  spend(700, DateTime(2026, 10, 12, 9), 'cat_coffee'),
  spend(1200, DateTime(2026, 10, 12, 13), 'cat_food'),
  spend(14500, DateTime(2026, 10, 6), 'cat_shopping'),
  spend(8000, DateTime(2026, 10, 3), 'cat_food'),
];

final bill = Subscription(
  id: 's1',
  name: 'Internet Idoom',
  amount: 2500,
  cycle: SubscriptionCycle.monthly,
  nextDueDate: DateTime(2026, 10, 20),
);

final debt = Debt(
  id: 'd1',
  type: DebtType.iOwe,
  person: 'أحمد',
  amount: 5000,
  date: DateTime(2026, 9, 1),
  dueDate: DateTime(2026, 10, 10),
  payments: [DebtPayment(amount: 2000, date: DateTime(2026, 9, 20))],
);

final oldDebt = Debt(
  id: 'd2',
  type: DebtType.owedToMe,
  person: 'سمير',
  amount: 3000,
  date: DateTime(2026, 6, 1),
);

DashboardData dashboard(List<MoneyTransaction> txns, {int subsDue = 2500}) =>
    buildDashboard(
      now: now,
      settings: settings,
      periodTransactions: txns,
      previousTransactions: const [],
      debts: [debt, oldDebt],
      unpaidSubscriptionsDue: subsDue,
    );

Future<void> pumpHome(
  WidgetTester tester, {
  required DashboardData data,
  String locale = 'ar',
  List<BeforePaydayItem>? before,
  bool alerts = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        uidProvider.overrideWithValue(null),
        nowProvider.overrideWith((ref) => now),
        localeProvider.overrideWith((ref) => locale),
        dashboardProvider.overrideWithValue(AsyncValue.data(data)),
        categoriesOrNullProvider.overrideWithValue(DefaultData.categories),
        recentTransactionsProvider.overrideWith(
          (ref) => Stream.value(sampleTxns),
        ),
        beforePaydayProvider.overrideWithValue(
          before ?? [BeforePaydayItem.debt(debt), BeforePaydayItem.bill(bill)],
        ),
        budgetAlertsProvider.overrideWithValue(
          alerts
              ? [
                  BudgetRow(
                    budget: const Budget(
                      id: '2026-10_cat_food',
                      month: '2026-10',
                      categoryId: 'cat_food',
                      limit: 10000,
                    ),
                    spent: 9200,
                  ),
                ]
              : const [],
        ),
        oldDebtsProvider.overrideWithValue(alerts ? [oldDebt] : const []),
        activeGoalsProvider.overrideWithValue([
          Goal(
            id: 'g1',
            name: 'عطلة الصيف',
            targetAmount: 80000,
            savedAmount: 32000,
          ),
        ]),
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
        home: const DashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('today comes first, then what is due before pay day', (
    tester,
  ) async {
    final data = dashboard(sampleTxns);
    await pumpHome(tester, data: data);
    expect(tester.takeException(), isNull);

    // (60000 - 24400 - 2500 subscription - 3000 debt + 1900 spent today) / 20
    expect(data.todayBudget, 1600);
    expect(data.spentToday, 1900);

    expect(find.text('تستطيع أن تصرف اليوم'), findsOneWidget);
    expect(find.text('قبل الراتب'), findsOneWidget);
    expect(find.text('Internet Idoom'), findsOneWidget);
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.textContaining('سمير'), findsOneWidget);
    expect(find.textContaining('ميزانية'), findsOneWidget);

    // Recent operations: an expense carries a minus sign, never a plus.
    expect(find.textContaining('-700'), findsOneWidget);
    expect(find.textContaining('+700'), findsNothing);

    // The hero is above the payday list, which is above the analysis.
    final hero = tester.getTopLeft(find.text('تستطيع أن تصرف اليوم')).dy;
    final payday = tester.getTopLeft(find.text('قبل الراتب')).dy;
    expect(hero, lessThan(payday));
    // Today and what is due fit in the first screen, without scrolling.
    expect(payday, lessThan(915));
  });

  testWidgets('overspending today is called out', (tester) async {
    final data = dashboard([
      ...sampleTxns,
      spend(3000, DateTime(2026, 10, 12, 16), 'cat_leisure'),
    ]);
    await pumpHome(tester, data: data);
    expect(tester.takeException(), isNull);
    expect(data.leftToday, isNegative);
    expect(find.textContaining('تجاوزت مصروف اليوم'), findsOneWidget);
  });

  testWidgets('a quiet day: nothing due, no alerts', (tester) async {
    await pumpHome(
      tester,
      data: dashboard(const [], subsDue: 0),
      before: const [],
      alerts: false,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('لا فواتير ولا ديون مستحقة قبل الراتب'), findsOneWidget);
    expect(find.textContaining('ميزانية'), findsNothing);
  });

  testWidgets('the period summary unfolds without errors', (tester) async {
    await pumpHome(tester, data: dashboard(sampleTxns));
    await tester.scrollUntilVisible(find.text('ملخص الفترة'), 300);
    await tester.tap(find.text('ملخص الفترة'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('كل التقارير'), findsOneWidget);
  });

  testWidgets('French layout works too', (tester) async {
    await pumpHome(tester, data: dashboard(sampleTxns), locale: 'fr');
    expect(tester.takeException(), isNull);
    expect(find.text('Avant la paie'), findsOneWidget);
  });
}
