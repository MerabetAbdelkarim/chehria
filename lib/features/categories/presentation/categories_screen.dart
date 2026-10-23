import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_data.dart';
import '../../../core/localization/s.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/async_view.dart';
import '../models/category.dart';
import '../providers/categories_providers.dart';
import 'category_actions.dart';
import 'category_form_sheet.dart';

/// Manage the categories used by transactions and budgets.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sProvider);
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.categories)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addCategory),
      ),
      body: AsyncValueView(
        value: categories,
        onRetry: () => ref.invalidate(categoriesProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.category_outlined,
              title: s.noCategories,
              subtitle: s.emptySubtitle,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final category = list[i];
              final color = Color(category.colorValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey(category.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await confirmAndDeleteCategory(context, ref, category);
                    return false;
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsetsDirectional.only(end: 22),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  child: Card(
                    child: ListTile(
                      onTap: () =>
                          CategoryFormSheet.show(context, category: category),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: .16),
                        child: Icon(
                          DefaultData.iconOf(category.iconCode),
                          color: color,
                          size: 21,
                        ),
                      ),
                      title: Text(
                        category.name(isAr: s.isAr),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(_kindLabel(category.kind, s)),
                      trailing: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _kindLabel(CategoryKind kind, S s) => switch (kind) {
    CategoryKind.both => s.kindBoth,
    CategoryKind.expense => s.kindExpense,
    CategoryKind.income => s.kindIncome,
  };
}
