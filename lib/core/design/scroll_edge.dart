/// The scroll edge effect.
///
/// On iOS 26 a bar carries no material while the content is at rest against it
/// — it is transparent, and the page runs edge to edge. The material appears
/// only once content has actually scrolled *under* the bar, which is what makes
/// it read as a pane the content passes beneath rather than a painted strip.
///
/// Apple's rules: **one scroll edge effect per view**, never stacked, and never
/// mixed with a hard divider doing the same job.
///
/// The app could not express this before. UIKit owns the native bars, Flutter
/// owns the scroll view, and nothing connected them — so the bars were pinned
/// to a single appearance and always showed their material. Every workaround we
/// tried for the date strip (band, no band, unpinned) was a symptom of that
/// missing signal.
library;

import 'package:flutter/widgets.dart';

/// Whether content is currently underneath the bars, for one route.
///
/// A `ValueNotifier` rather than state on a `StatefulWidget`: the bars are
/// slivers built by delegates that rebuild independently of the scroll view, so
/// they need something they can listen to rather than something passed down.
class ScrollEdgeState extends ValueNotifier<bool> {
  ScrollEdgeState() : super(false);
}

/// Publishes the scroll-edge state to everything under it.
class ScrollEdgeScope extends InheritedNotifier<ScrollEdgeState> {
  const ScrollEdgeScope({
    super.key,
    required ScrollEdgeState state,
    required super.child,
  }) : super(notifier: state);

  /// Whether content is under the bars. `false` when no scope is installed,
  /// which is the Android shell and every widget test — both of which then get
  /// the at-rest appearance, the correct default.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ScrollEdgeScope>()
          ?.notifier
          ?.value ??
      false;
}

/// Wraps a page's scroll view and reduces its offset to the one bit the bars
/// need.
///
/// [onChanged] fires only on a transition, not on every scroll frame — the
/// native side is across a platform channel, and sending it a message per frame
/// would be the most expensive thing in the app.
class ScrollEdgeObserver extends StatefulWidget {
  const ScrollEdgeObserver({
    super.key,
    required this.child,
    this.onChanged,
  });

  final Widget child;
  final ValueChanged<bool>? onChanged;

  @override
  State<ScrollEdgeObserver> createState() => _ScrollEdgeObserverState();
}

class _ScrollEdgeObserverState extends State<ScrollEdgeObserver> {
  final _state = ScrollEdgeState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  /// A couple of points of slack, so a rubber-band overscroll at the very top
  /// — which iOS does on every flick — doesn't flicker the material on and off.
  static const _threshold = 2.0;

  bool _handle(ScrollNotification notification) {
    // Only the primary vertical scroll view of the page. A horizontal filter
    // bar or a nested list must not speak for the whole screen.
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    final under = notification.metrics.pixels > _threshold;
    if (under == _state.value) return false;
    _state.value = under;
    widget.onChanged?.call(under);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handle,
      child: ScrollEdgeScope(state: _state, child: widget.child),
    );
  }
}
