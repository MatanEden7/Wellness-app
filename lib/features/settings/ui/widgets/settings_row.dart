import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/ios/inset_list.dart';

/// A single row in an Apple-style settings list.
///
/// [icon] is shown in a tinted rounded square ([iconColor] at 15% opacity).
/// [value] renders right-aligned in muted text.
/// A chevron is added when [onTap] is provided and [showChevron] is true.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.destructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    // `InsetRow` already draws the value, the chevron and the tinted icon box,
    // and does it without needing a `Material` ancestor -- which a `ListTile`
    // inside a glass section does not have. Suppressing the chevron is the one
    // thing it has no flag for, so that case passes an empty trailing widget.
    return InsetRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      value: value,
      isDestructive: destructive,
      onTap: onTap,
      trailing:
          (onTap != null && !showChevron) ? _ValueOnly(value: value) : null,
    );
  }
}

/// The trailing slot for a row that navigates but should not advertise a
/// chevron -- a row whose tap opens a sheet in place rather than pushing.
class _ValueOnly extends StatelessWidget {
  const _ValueOnly({this.value});
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      value!,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}

/// A switch variant of [SettingsRow].
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Was a `SwitchListTile`, then a `ListTile`. Both resolve their colours and
    // ink against the nearest `Material`, and inside a glass settings section
    // there is none -- Flutter asserts rather than degrading. `InsetRow` is the
    // grouped-list row this always wanted to be, and it owns its own metrics,
    // so the hand-set contentPadding goes with it.
    return InsetRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    );
  }
}
