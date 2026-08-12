import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, ThemeData;

import '../../l10n/app_localizations.dart';
import '../design/tokens.dart';
import 'native_ui.dart';

/// Transient confirmations and one-button alerts.
///
/// Replaces every `ScaffoldMessenger.showSnackBar` in the app. A SnackBar is a
/// Material component with a Material shape, a Material motion curve and a
/// left-aligned action button; on an iPhone it is the single most obviously
/// Android thing on screen. On iOS these route to a real `UIVisualEffectView`
/// capsule presented on the app window ([BannerPresenter] in Swift); the
/// Flutter implementations below exist only for Android and widget tests.

/// Shows a transient message. Never awaits — callers fire and continue.
void showAppBanner(
  BuildContext context,
  String message, {
  BannerKind kind = BannerKind.info,
}) {
  if (NativeUI.banner(message, kind: kind)) return;
  _FlutterBanner.show(context, message, kind);
}

/// Convenience for the overwhelmingly common two cases, so call sites read as
/// intent rather than as configuration.
void showAppSuccess(BuildContext context, String message) =>
    showAppBanner(context, message, kind: BannerKind.success);

void showAppError(BuildContext context, String message) =>
    showAppBanner(context, message, kind: BannerKind.error);

/// A one-button alert — for a failure the user must acknowledge, where a
/// banner would scroll past before it was read.
Future<void> showAppInfo(
  BuildContext context, {
  required String title,
  String? message,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (await NativeUI.info(
    title: title,
    message: message,
    buttonLabel: l10n.ok,
  )) {
    return;
  }

  if (!context.mounted) return;

  await showCupertinoDialog<void>(
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
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}

// ─── Flutter fallback ────────────────────────────────────────────────────────

/// The Android/widget-test banner. Deliberately a plain overlay entry rather
/// than a SnackBar: it keeps one code path for "a message appeared" that tests
/// can find by text, without dragging `ScaffoldMessenger` (and therefore a
/// `Scaffold`) back into pages that no longer have one.
class _FlutterBanner {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(BuildContext context, String message, BannerKind kind) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss();

    final entry = OverlayEntry(
      builder: (overlayContext) => _BannerWidget(message: message, kind: kind),
    );
    _current = entry;
    overlay.insert(entry);

    _timer = Timer(const Duration(milliseconds: 2200), _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _BannerWidget extends StatelessWidget {
  const _BannerWidget({required this.message, required this.kind});

  final String message;
  final BannerKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Positioned(
      top: media.padding.top + Space.sm,
      left: Space.md,
      right: Space.md,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, size: 20, color: _tint(theme)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (kind) {
        BannerKind.success => CupertinoIcons.check_mark_circled_solid,
        BannerKind.error => CupertinoIcons.exclamationmark_triangle_fill,
        BannerKind.info => CupertinoIcons.info_circle_fill,
      };

  Color _tint(ThemeData theme) => switch (kind) {
        BannerKind.success => CupertinoColors.systemGreen,
        BannerKind.error => theme.colorScheme.error,
        BannerKind.info => theme.colorScheme.onSurface.withValues(alpha: 0.6),
      };
}
