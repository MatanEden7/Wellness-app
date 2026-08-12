import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets.dart';
import 'app_scaffold.dart';
import '../../core/design/surfaces.dart';
import '../design/tokens.dart';
import 'pressable.dart';

/// An iOS inset-grouped section: an optional caps header, then rows sharing
/// one rounded container with hairlines between them.
///
/// This is the shape Settings, and every list of homogeneous rows in an
/// Apple app, is built from. It replaces the app's habit of giving every
/// single row its own floating `Card` -- fine for a card with four macro
/// badges in it, wrong for a list of one-line rows, where it reads as
/// clutter and wastes 12pt of vertical space per item.
class InsetSection extends StatelessWidget {
  final List<Widget> children;

  /// Small grey caps line above the group.
  final String? header;

  /// Grey explanatory line below the group.
  final String? footer;

  const InsetSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
            child: Text(
              header!.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                letterSpacing: -0.08,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ContentSurface(
          borderRadius: BorderRadius.circular(12),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                // Separators start at the text, not the screen edge.
                if (i > 0) const AppHairline(indent: 16),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
            child: Text(
              footer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}

/// One row inside an [InsetSection]: tinted icon, title, optional subtitle,
/// optional trailing value, and a chevron when it navigates.
class InsetRow extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Grey value shown before the chevron -- "72 kg", "Hebrew", "3 items".
  final String? value;

  final IconData? icon;
  final Color? iconColor;

  /// Replaces the trailing chevron/value entirely (a switch, a spinner).
  final Widget? trailing;

  final VoidCallback? onTap;

  /// Renders the title in red -- "Delete account", "Reset".
  final bool isDestructive;

  const InsetRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    // A grouped-list row, so it takes the grey wash a Settings row does
    // rather than dimming its own content.
    return Pressable(
      onTap: onTap,
      style: PressStyle.highlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.lg, vertical: Space.md),
        child: Row(
          children: [
            if (icon != null) ...[
              SettingsIconBadge(icon!, color: iconColor, size: 18),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      color: isDestructive
                          ? CupertinoColors.destructiveRed
                          : theme.colorScheme.onSurface,
                    ),
                    // One line when a value sits beside it -- a wrapped title
                    // next to a short value reads as a layout failure. Rows
                    // without a value have the width to spare for two.
                    maxLines: value == null ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null)
                // A hard cap rather than a Flexible. An unconstrained value
                // overflows the row once it is a translated phrase instead of
                // a number, but making it Flexible is worse: Expanded and
                // Flexible both default to flex 1, so they split the free
                // space evenly and the *title* starts wrapping -- "Primary
                // Metric" over two lines next to eight characters of value.
                // Capping the value keeps the title's claim on the row, which
                // is the priority iOS gives it.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.38,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontSize: 17, color: muted),
                    ),
                  ),
                ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
