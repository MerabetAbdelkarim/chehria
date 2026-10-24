import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_providers.dart';
import 'my_data_section.dart';

/// "Account & data": JSON backup and permanent account deletion.
class AccountDataScreen extends ConsumerWidget {
  const AccountDataScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const AccountDataScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.accountAndData)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: const [MyDataSection()],
      ),
    );
  }
}
