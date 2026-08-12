import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import 'native_ui.dart';

// Callers configuring a press almost always want to pick its haptic in the
// same breath, so the enum travels with the widget.
export 'native_ui.dart' show HapticKind;

/// iOS press feedback, in place of the Material ink ripple.
///
/// The ripple is the loudest Android tell left in the app: a coloured circle
/// grows from the touch point and washes over the control. iOS has no such
/// thing. It does one of two things instead, and which one depends on what was
/// tapped — [PressStyle] is that choice.
///
/// This also replaces `InkWell`'s hidden requirement for a `Material` ancestor.
/// Several cards carried a `Material(type: transparency)` wrapper that existed
/// only so the ripple had somewhere to paint.
enum PressStyle {
  /// The content dims. What a button, a card or a tile does — including every
  /// tappable tile on the dashboard.
  fade,

  /// A grey fill washes the row. What a table row in Settings, Mail or
  /// Messages does, and the right choice for anything inside a grouped list.
  highlight,
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.style = PressStyle.fade,
    this.haptic,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Needed by [PressStyle.highlight] so the fill matches the corner it sits
  /// in; ignored by [PressStyle.fade].
  final BorderRadius? borderRadius;

  final PressStyle style;

  /// Fires on tap-down, not on tap-up: iOS haptics accompany the touch, and
  /// firing after the gesture resolves feels like a delayed echo.
  final HapticKind? haptic;

  final HitTestBehavior behavior;

  bool get _enabled => onTap != null || onLongPress != null;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (!widget._enabled || _down == value) return;
    setState(() => _down = value);
    if (value && widget.haptic != null) NativeUI.haptic(widget.haptic!);
  }

  @override
  Widget build(BuildContext context) {
    // 100ms down / 200ms up is UIKit's own asymmetry: the press must register
    // instantly, while the release should not snap.
    final duration = Duration(milliseconds: _down ? 100 : 200);

    Widget content = widget.child;

    if (widget.style == PressStyle.highlight) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _down ? 1 : 0,
                duration: duration,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemFill.resolveFrom(context),
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      content = AnimatedOpacity(
        opacity: _down ? 0.45 : 1,
        duration: duration,
        child: content,
      );
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      child: content,
    );
  }
}
