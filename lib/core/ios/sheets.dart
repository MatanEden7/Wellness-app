import 'package:flutter/cupertino.dart';

import '../../l10n/app_localizations.dart';
import '../ui_constants.dart';
import 'app_scaffold.dart';

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
}) {
  final l10n = AppLocalizations.of(context)!;

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
