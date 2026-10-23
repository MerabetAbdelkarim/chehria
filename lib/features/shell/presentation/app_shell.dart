import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_providers.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../debts/presentation/debts_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../transactions/presentation/fast_add_transaction_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';

/// Bottom navigation shell of the app.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sProvider);
    final showFab = _index == 0 || _index == 1;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          TransactionsScreen(),
          DebtsScreen(),
          AccountsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FastAddTransactionScreen(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.quickAdd),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: s.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: s.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.handshake_outlined),
            selectedIcon: const Icon(Icons.handshake_rounded),
            label: s.navDebts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: s.navAccounts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}
