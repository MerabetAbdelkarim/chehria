import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_providers.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../dart/presentation/dart_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../seasonal/presentation/seasonal_screen.dart';
import '../../subscriptions/presentation/subscriptions_screen.dart';
import 'settings_widgets.dart';

/// "Money tools": the app's features beyond the daily budget, one per row
/// with a line saying what each one is for.
class MoneyToolsScreen extends ConsumerWidget {
  const MoneyToolsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const MoneyToolsScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    void open(Route<void> route) => Navigator.of(context).push(route);

    return Scaffold(
      appBar: AppBar(title: Text(s.moneyTools)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SettingsSection(
            children: [
              SettingsTile(
                icon: Icons.autorenew_rounded,
                color: const Color(0xFF00897B),
                title: s.subscriptions,
                subtitle: s.subscriptionsHint,
                onTap: () => open(SubscriptionsScreen.route()),
              ),
              SettingsTile(
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFFE65100),
                title: s.budgets,
                subtitle: s.budgetsHint,
                onTap: () => open(BudgetsScreen.route()),
              ),
              SettingsTile(
                icon: Icons.savings_rounded,
                color: const Color(0xFF1E88E5),
                title: s.goals,
                subtitle: s.goalsHint,
                onTap: () => open(GoalsScreen.route()),
              ),
              SettingsTile(
                icon: Icons.groups_rounded,
                color: const Color(0xFF6D4C9F),
                title: s.dartGroups,
                subtitle: s.dartGroupsHint,
                onTap: () => open(DartScreen.route()),
              ),
              SettingsTile(
                icon: Icons.event_available_rounded,
                color: const Color(0xFFC2185B),
                title: s.seasonal,
                subtitle: s.seasonalHint,
                onTap: () => open(SeasonalScreen.route()),
              ),
              SettingsTile(
                icon: Icons.insights_rounded,
                color: const Color(0xFF00873D),
                title: s.reports,
                subtitle: s.reportsHint,
                onTap: () => open(ReportsScreen.route()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
