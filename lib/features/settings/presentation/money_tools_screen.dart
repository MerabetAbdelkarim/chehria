import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_providers.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../dart/presentation/dart_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../seasonal/presentation/seasonal_screen.dart';
import '../../subscriptions/presentation/subscriptions_screen.dart';

/// "Money tools": the app's features beyond the daily budget, as a grid.
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
          _ToolsGrid(
            tools: [
              _Tool(
                Icons.autorenew_rounded,
                s.subscriptions,
                const Color(0xFF00897B),
                () => open(SubscriptionsScreen.route()),
              ),
              _Tool(
                Icons.pie_chart_rounded,
                s.budgets,
                const Color(0xFFE65100),
                () => open(BudgetsScreen.route()),
              ),
              _Tool(
                Icons.savings_rounded,
                s.toolGoals,
                const Color(0xFF1E88E5),
                () => open(GoalsScreen.route()),
              ),
              _Tool(
                Icons.groups_rounded,
                s.dartGroups,
                const Color(0xFF6D4C9F),
                () => open(DartScreen.route()),
              ),
              _Tool(
                Icons.event_available_rounded,
                s.toolSeasonal,
                const Color(0xFFC2185B),
                () => open(SeasonalScreen.route()),
              ),
              _Tool(
                Icons.insights_rounded,
                s.reports,
                const Color(0xFF00873D),
                () => open(ReportsScreen.route()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tool {
  const _Tool(this.icon, this.label, this.color, this.onTap);

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Rows of three tiles. Rows (not a fixed-ratio grid) so a tile grows with
/// large system fonts instead of clipping its label; tiles in a row keep the
/// same height.
class _ToolsGrid extends StatelessWidget {
  const _ToolsGrid({required this.tools});

  final List<_Tool> tools;

  static const int _perRow = 3;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_Tool>>[
      for (var i = 0; i < tools.length; i += _perRow)
        tools.sublist(i, (i + _perRow).clamp(0, tools.length)),
    ];
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _perRow; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: i < rows[r].length
                        ? _ToolTile(tool: rows[r][i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tool.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 16, 6, 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tool.icon, color: tool.color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                tool.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
