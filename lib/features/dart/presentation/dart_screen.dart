import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/async_view.dart';
import '../providers/dart_providers.dart';
import 'dart_detail_screen.dart';
import 'dart_form_sheet.dart';
import 'dart_tile.dart';

/// List of rotating savings groups.
class DartScreen extends ConsumerWidget {
  const DartScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const DartScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final groups = ref.watch(dartGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.dartGroups)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DartFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addDart),
      ),
      body: AsyncValueView(
        value: groups,
        onRetry: () => ref.invalidate(dartGroupsProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.groups_outlined,
              title: s.noDartYet,
              subtitle: s.dartPaymentsHint,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: list.length,
            itemBuilder: (context, i) => DartTile(
              key: ValueKey(list[i].id),
              group: list[i],
              onTap: () => Navigator.of(
                context,
              ).push(DartDetailScreen.route(list[i].id)),
            ),
          );
        },
      ),
    );
  }
}
