import 'package:flutter/cupertino.dart';

import '../../l10n/app_localizations.dart';
import '../ui_constants.dart';
import 'app_scaffold.dart';
import 'native_ui.dart';

/// One button in an [showAppActionSheet].
class AppAction {
  final String label;
  final IconData? icon;

  /// Red, and sorted to the bottom by iOS convention.
  final bool isDestructive;

  /// Semibold -- the action the sheet exists for.
  final bool isDefault;

  final VoidCallback onPressed;

  const AppAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

/// The iOS action sheet: the replacement for every `PopupMenuButton` this app
/// used to hang off the corner of a card.
///
/// A three-dot menu that opens a small Material popup anchored to the tap is
/// the one thing that reads as "not an iPhone app" from across the room. The
/// same choices presented as a sheet from the bottom, with a separated
/// Cancel, are what iOS uses for exactly this job.
///
/// The sheet pops itself before running the chosen callback, so callers can
/// navigate or open another sheet without stacking one on top of the other.
Future<void> showAppActionSheet({
  required BuildContext context,
  String? title,
  String? message,
  required List<AppAction> actions,
}) async {
  final l10n = AppLocalizations.of(context)!;

  // Real UIKit first. `presentActionSheet` returns the id of the tapped item,
  // or null for Cancel -- and the NativeResult wrapper is what tells those
  // apart from "no bridge", so a Cancel here must not fall through and open
  // the Flutter sheet on top of the dismissal.
  final native = await NativeUI.actionSheet(
    title: title,
    message: message,
    items: [
      for (final (index, action) in actions.indexed)
        ActionSheetItem(
          id: '$index',
          title: action.label,
          isDestructive: action.isDestructive,
        ),
    ],
    cancelLabel: l10n.cancel,
  );

  if (native != null) {
    final id = native.value;
    if (id == null) return;
    final index = int.tryParse(id);
    if (index != null && index >= 0 && index < actions.length) {
      actions[index].onPressed();
    }
    return;
  }

  if (!context.mounted) return;

  // Fallback: Android, and widget tests, where there is no channel to answer.
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: [
        for (final action in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            isDefaultAction: action.isDefault,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              action.onPressed();
            },
            child: action.icon == null
                ? Text(action.label)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon, size: 20),
                      const SizedBox(width: 8),
                      Flexible(child: Text(action.label)),
                    ],
                  ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: Text(l10n.cancel),
      ),
    ),
  );
}

/// Select-one-of-a-few, as an iOS action sheet.
///
/// Replaces the `AlertDialog` + `RadioListTile` column that every settings
/// picker in the app was built from. A radio list is a Material control — iOS
/// has no radio button at all — and the dialog it sat in was a centred Material
/// card. The current value is marked with a checkmark, which is how iOS shows
/// the selected row in a list of choices.
///
/// Returns null if the user cancelled.
Future<T?> showAppPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T? current,
  required String Function(T) labelOf,
}) async {
  T? chosen;
  await showAppActionSheet(
    context: context,
    title: title,
    actions: [
      for (final option in options)
        AppAction(
          // U+2713 rather than a leading icon: the native action sheet takes
          // titles only, so the mark has to live in the string.
          label: option == current ? '✓ ${labelOf(option)}' : labelOf(option),
          isDefault: option == current,
          onPressed: () => chosen = option,
        ),
    ],
  );
  return chosen;
}

/// iOS confirmation alert. Returns true only if the user confirmed.
///
/// Replaces the `AlertDialog` + two `TextButton`s that every delete path in
/// the app had its own copy of.
Future<bool> showAppConfirm({
  required BuildContext context,
  required String title,
  String? message,
  required String confirmLabel,
  bool isDestructive = true,
}) async {
  final l10n = AppLocalizations.of(context)!;

  // A real UIAlertController -- system font metrics, system button ordering,
  // and the dim/blur behind it that Flutter can only approximate.
  final native = await NativeUI.confirm(
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: l10n.cancel,
    isDestructive: isDestructive,
  );
  if (native != null) return native;

  if (!context.mounted) return false;

  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message),
            ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

/// Pushes [page] as a full-screen modal that slides up from the bottom.
///
/// This is what iOS does with anything that has more than a couple of fields,
/// and it is what the app's add-food and add-exercise forms become. As
/// centred `Dialog`s they had to be capped at 85% of the screen and scrolled
/// internally, with the Save button repeatedly ending up off-screen; a modal
/// page has the whole screen, and the keyboard inset is handled for it.
///
/// [page] is normally an [AppFormPage], which supplies the Cancel/confirm
/// chrome. It owns its own state and pops itself with a result.
Future<T?> pushModalPage<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    CupertinoPageRoute<T>(fullscreenDialog: true, builder: (_) => page),
  );
}

/// The standard body of a modal form: Cancel on the left of the navigation
/// bar, the confirming action on the right, fields below.
class AppFormPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget confirm;

  const AppFormPage({
    super.key,
    required this.title,
    required this.child,
    required this.confirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: title,
      leading: NavBarAction(
        label: l10n.cancel,
        tooltip: l10n.cancel,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [confirm],
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            UIConstants.screenHorizontalPadding,
            UIConstants.cardSpacing,
            UIConstants.screenHorizontalPadding,
            // Room for the keyboard: a modal page is full height, so the
            // last field would otherwise sit under it.
            UIConstants.sectionSpacing +
                MediaQuery.of(context).viewInsets.bottom,
          ),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}
