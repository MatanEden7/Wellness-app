import 'package:flutter/material.dart';

import '../../core/design/surfaces.dart';

/// One tile in a [ShortcutRow].
class AppShortcut {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Tint for the glyph; defaults to the screen's area colour.
  final Color? color;

  const AppShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// A row of equal-width shortcut tiles, sitting under the summary card on an
/// area's home screen.
///
/// This is where the secondary destinations of an area live -- the food
/// catalog and meal templates, the exercise library and workout templates.
/// They used to be unlabelled glyphs crowded into the navigation bar (the
/// workouts page had already had to drop two of them because the title
/// wrapped on a 393pt screen). As tiles they are labelled, reachable with a
/// thumb, and identical on both screens.
class ShortcutRow extends StatelessWidget {
  final List<AppShortcut> shortcuts;

  const ShortcutRow({super.key, required this.shortcuts});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight, not a bare `crossAxisAlignment: stretch`: the row sits
    // inside a sliver, where the incoming height constraint is unbounded, and
    // stretching against an unbounded constraint asks the tiles to be
    // infinitely tall -- which throws in layout and takes the whole screen
    // down with it. This gives the row a real height (the tallest tile's)
    // first, so the shorter ones can then stretch to match.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < shortcuts.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _ShortcutTile(shortcut: shortcuts[i])),
          ],
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final AppShortcut shortcut;

  const _ShortcutTile({required this.shortcut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = shortcut.color ?? theme.colorScheme.primary;

    return Tooltip(
      message: shortcut.label,
      child: ContentSurface(
        borderRadius: BorderRadius.circular(14),
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: shortcut.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(shortcut.icon, size: 24, color: tint),
                  const SizedBox(height: 8),
                  Text(
                    shortcut.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
