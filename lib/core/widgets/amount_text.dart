import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/formatters.dart';
import '../../features/settings/providers/settings_providers.dart';

/// Amount text honouring the user's currency display setting.
class AmountText extends ConsumerWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.sign = false,
    this.style,
    this.colorBySign = false,
    this.millionsMode,
  });

  final int amount;
  final bool sign;

  /// Green for income / red for expense when `true`.
  final bool colorBySign;
  final TextStyle? style;
  final bool? millionsMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool useMillions = millionsMode ?? ref.watch(millionsModeProvider);
    final text = sign
        ? formatSigned(amount, millionsMode: useMillions)
        : formatAmount(amount, millionsMode: useMillions);

    Color? color;
    if (colorBySign) {
      color = amount >= 0 ? const Color(0xFF00873D) : theme.colorScheme.error;
    }
    return Text(
      text,
      style:
          style ??
          theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
    );
  }
}

/// Small colored dot used next to categories/accounts.
class CategoryDot extends StatelessWidget {
  const CategoryDot(this.color, {super.key, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
