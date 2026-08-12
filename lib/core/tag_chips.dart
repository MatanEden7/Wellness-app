import 'package:flutter/material.dart';

import 'ios/glass.dart';
import 'design/tokens.dart';

/// A labelled wrap of filter chips for editing a `Set<T>` of enum tags.
///
/// Used by the food and exercise editors so user-created content can be
/// tagged the same way seeded content is. That matters more than it looks:
/// `ProfileFit` treats untagged content as fitting *everyone*, which is the
/// right default for a half-filled form but means anything the user adds
/// escapes filtering entirely until it's labelled. Without an editor, the
/// whole tagging system decays as soon as someone adds their own food.
class TagChips<T> extends StatelessWidget {
  const TagChips({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in options)
              // A glass pill rather than a Material `FilterChip`: the chip
              // brings its own opaque surface and its own selected colour,
              // neither of which can be made translucent from the outside.
              GlassButton(
                prominent: selected.contains(option),
                minHeight: Sizes.control,
                borderRadius: BorderRadius.circular(17),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                onPressed: () {
                  final isSelected = !selected.contains(option);
                  final next = Set<T>.from(selected);
                  if (isSelected) {
                    next.add(option);
                  } else {
                    next.remove(option);
                  }
                  onChanged(next);
                },
                child: Text(
                  labelOf(option),
                  style: TextStyle(
                    fontSize: 14,
                    color: selected.contains(option)
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
