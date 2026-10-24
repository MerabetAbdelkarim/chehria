import 'package:flutter/material.dart';

/// A titled group of settings rows: a small label above one card, with thin
/// dividers between the rows. Every part of the settings screen uses it so the
/// page reads as a few clear blocks.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});

  /// Omitted when the page title already names the group.
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 8),
            child: Text(
              title!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One settings row: a tinted icon, a title, and either the current value
/// (with a chevron when tapping opens something) or a custom trailing widget.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.color,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Current value shown at the end of the row (e.g. "العربية").
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Icon tint; defaults to the primary color.
  final Color? color;

  /// Red row for irreversible actions.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = destructive ? scheme.error : (color ?? scheme.primary);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 19, color: tint),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: destructive ? scheme.error : null,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
      trailing:
          trailing ??
          (value == null && onTap == null
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (onTap != null && !destructive)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                )),
    );
  }
}

/// One option of [showSettingsChoice].
class SettingsChoice<T> {
  const SettingsChoice(this.value, this.label, {this.hint});

  final T value;
  final String label;
  final String? hint;
}

/// Bottom sheet listing [choices]; returns the picked value, or `null` when
/// dismissed.
Future<T?> showSettingsChoice<T>(
  BuildContext context, {
  required String title,
  required List<SettingsChoice<T>> choices,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final c in choices)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(c.label),
                  subtitle: c.hint == null ? null : Text(c.hint!),
                  trailing: c.value == selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : const Icon(Icons.circle_outlined),
                  onTap: () => Navigator.of(context).pop(c.value),
                ),
            ],
          ),
        ),
      );
    },
  );
}
