import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'glass.dart';
import 'sheets.dart';
import '../design/tokens.dart';

/// A list row that can be swiped from the trailing edge to delete, swiped
/// from the leading edge to edit, and long-pressed for its full set of
/// actions.
///
/// The two swipe directions mirror each other on purpose: destructive one
/// way, constructive the other, which is the split iOS uses in Mail and
/// Reminders. All of it is what an iPhone user reaches for first on a list of
/// things they own -- meals, templates, foods, exercises, logged nights. The
/// row keeps an explicit [AppRowMenuButton] as well, because a gesture with
/// no visible affordance is undiscoverable for anything destructive.
///
/// Deletion is confirmed before it happens, and the row is *not* removed
/// optimistically: the underlying stream rebuilds the list, so dismissing the
/// widget itself would make the row vanish twice.
class SwipeActionRow extends StatelessWidget {
  final Widget child;

  /// Required by [Dismissible] -- must be stable and unique per row.
  final Key rowKey;

  /// Omit to disable the swipe gesture (a row that cannot be deleted, such as
  /// a starter-catalog item).
  final Future<void> Function()? onDelete;

  final String deleteLabel;

  /// Swiping from the leading edge runs this. Omit for a row with nothing to
  /// edit.
  final VoidCallback? onEdit;

  final String? editLabel;

  /// Shown in the confirmation alert before [onDelete] runs.
  final String confirmTitle;
  final String? confirmMessage;

  /// Offered on long press. Deletion is appended automatically when
  /// [onDelete] is set, so don't include it here.
  final List<AppAction> actions;

  /// Set false where long-press already means something else -- inside a
  /// [ReorderableListView], where it starts a drag.
  final bool enableLongPressMenu;

  const SwipeActionRow({
    super.key,
    required this.rowKey,
    required this.child,
    required this.deleteLabel,
    required this.confirmTitle,
    this.confirmMessage,
    this.onDelete,
    this.onEdit,
    this.editLabel,
    this.actions = const [],
    this.enableLongPressMenu = true,
  });

  List<AppAction> _allActions(BuildContext context) => [
        ...actions,
        if (onDelete != null)
          AppAction(
            label: deleteLabel,
            icon: CupertinoIcons.delete,
            isDestructive: true,
            onPressed: () => _confirmAndDelete(context),
          ),
      ];

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showAppConfirm(
      context: context,
      title: confirmTitle,
      message: confirmMessage,
      confirmLabel: deleteLabel,
    );
    if (confirmed) await onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final row = GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onLongPress: !enableLongPressMenu || _allActions(context).isEmpty
          ? null
          : () => showAppActionSheet(
                context: context,
                actions: _allActions(context),
              ),
      child: child,
    );

    final canDelete = onDelete != null;
    final canEdit = onEdit != null;
    if (!canDelete && !canEdit) return row;

    return Dismissible(
      key: rowKey,
      direction: canDelete && canEdit
          ? DismissDirection.horizontal
          : (canDelete
              ? DismissDirection.endToStart
              : DismissDirection.startToEnd),
      // Full-width swipes act outright on iOS; require a deliberate one.
      dismissThresholds: const {
        DismissDirection.endToStart: 0.4,
        DismissDirection.startToEnd: 0.4,
      },
      background: canEdit
          ? _SwipeBackground(
              label: editLabel ?? '',
              icon: CupertinoIcons.pencil,
              color: CupertinoColors.systemBlue,
              alignment: AlignmentDirectional.centerStart,
            )
          : const SizedBox.shrink(),
      secondaryBackground: canDelete
          ? _SwipeBackground(
              label: deleteLabel,
              icon: CupertinoIcons.delete,
              color: CupertinoColors.destructiveRed,
              alignment: AlignmentDirectional.centerEnd,
            )
          : const SizedBox.shrink(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit!();
          return false;
        }
        final confirmed = await showAppConfirm(
          context: context,
          title: confirmTitle,
          message: confirmMessage,
          confirmLabel: deleteLabel,
        );
        if (confirmed) await onDelete!();
        // Always false: the list is stream-driven and will drop the row on
        // its own. Returning true removes it here too, and the row flickers
        // back in for a frame before the stream catches up.
        return false;
      },
      child: row,
    );
  }
}

/// The coloured panel revealed behind a half-swiped row.
class _SwipeBackground extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final AlignmentDirectional alignment;

  const _SwipeBackground({
    required this.label,
    required this.icon,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The ellipsis button iOS puts on a row that has more than one action --
/// what the app's `PopupMenuButton`s become.
class AppRowMenuButton extends StatelessWidget {
  final List<AppAction> actions;
  final String tooltip;

  /// Optional sheet heading, usually the name of the thing being acted on.
  final String? title;

  const AppRowMenuButton({
    super.key,
    required this.actions,
    required this.tooltip,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassButton(
        minHeight: Sizes.control,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm, vertical: Space.sm),
        onPressed: () => showAppActionSheet(
          context: context,
          title: title,
          actions: actions,
        ),
        child: Icon(
          CupertinoIcons.ellipsis_circle,
          size: 22,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
