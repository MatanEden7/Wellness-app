import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../ui_constants.dart';

/// The iOS sliding segmented control, themed from the app's colour scheme.
///
/// Replaces the Material `TabBar` on the food catalog and the row of
/// `ChoiceChip`s used for filtering: both are Android idioms, and the tab bar
/// in particular put a second, differently-styled bar directly under the
/// navigation bar.
class AppSegmented<T extends Object> extends StatelessWidget {
  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  const AppSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor:
            theme.colorScheme.onSurface.withValues(alpha: 0.08),
        thumbColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        onValueChanged: (next) {
          if (next != null) onChanged(next);
        },
        children: {
          for (final entry in segments.entries)
            entry.key: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                entry.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight:
                      entry.key == value ? FontWeight.w600 : FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        },
      ),
    );
  }
}

/// The rounded grey iOS search field, with the clear button built in.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CupertinoSearchTextField(
      controller: controller,
      placeholder: placeholder,
      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 17),
      placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
      ),
      backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.07),
      itemColor: theme.colorScheme.onSurface.withValues(alpha: 0.45),
      prefixIcon: Icon(
        CupertinoIcons.search,
        size: 18,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

/// A horizontally scrolling row of filter pills, iOS-style: filled when
/// selected, hairline-outlined when not.
class AppFilterBar<T> extends StatelessWidget {
  final List<T> options;
  final T? value;
  final String Function(T) labelOf;

  /// Label for the "no filter" pill that leads the row. Omit for a bar where
  /// a selection is mandatory.
  final String? allLabel;

  final ValueChanged<T?> onChanged;

  const AppFilterBar({
    super.key,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.allLabel,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <(T?, String)>[
      if (allLabel != null) (null, allLabel!),
      for (final option in options) (option, labelOf(option)),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.screenHorizontalPadding,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final (option, label) = entries[index];
        return _FilterPill(
          label: label,
          selected: option == value,
          onTap: () => onChanged(option),
        );
      },
    );
  }
}

/// The strip shown above a filtered list explaining why it is short, with a
/// one-tap escape hatch.
///
/// Counting the hidden rows is the point: silently showing a shorter list
/// looks like missing data, which is what makes hiding feel broken. The food
/// catalog and the exercise library each had their own private pair of these;
/// this is the one both use.
class FilterBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const FilterBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          UIConstants.screenHorizontalPadding, 8, 8, 8),
      color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
      child: Row(
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(44, 36),
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(fontSize: 15, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
