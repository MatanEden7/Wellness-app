/// The content layer.
///
/// Apple's iOS 26 design system has three layers, and the material each one
/// gets is not a matter of taste:
///
///   * **content** — cards, list groups, rows, charts. Opaque.
///   * **functional** — bars, sheets, buttons, chips, anything that floats
///     *above* content. Liquid Glass (`lib/core/ios/glass.dart`).
///   * **navigation** — the native nav bar and tab bar. Real UIKit glass.
///
/// "Applying Liquid Glass directly to content" is on Apple's explicit list of
/// anti-patterns, and the reason is legibility rather than taste: glass earns
/// its meaning by being the layer that floats. When every card is also glass,
/// nothing is — which is exactly how this app's screens ended up reading as
/// washed out after the material was applied everywhere.
///
/// This file is what content uses instead. Same geometry as [GlassSurface] —
/// same radii, same padding, same hairline — so the two are interchangeable at
/// the call site and the *only* difference is the material.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// An opaque surface on the content layer.
class ContentSurface extends StatelessWidget {
  const ContentSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.color,
    this.border,
    this.showBorder = true,
    this.elevated = false,
  });

  final Widget child;

  /// Defaults to [Radii.card]. Nested surfaces should use
  /// [Radii.inner] against their parent rather than picking a number.
  final BorderRadius? borderRadius;

  final EdgeInsetsGeometry? padding;

  /// Defaults to the theme's `surface`, or `surfaceContainerHighest` when
  /// [elevated].
  final Color? color;

  final BoxBorder? border;
  final bool showBorder;

  /// A surface resting on another surface — a card inside a card, a row inside
  /// a group. Steps to the third rung of the theme's ramp so the nesting is
  /// visible without a heavier border.
  final bool elevated;

  /// An accent-tinted panel: badges, status banners, the tinted rows that carry
  /// a section colour. The same shape the app already used as
  /// `BoxDecoration(color: accent.withValues(alpha: …))`, so converting one is
  /// a rename.
  factory ContentSurface.tinted({
    Key? key,
    required Color color,
    required Widget child,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    BoxBorder? border,
  }) =>
      ContentSurface(
        key: key,
        color: color,
        borderRadius: borderRadius,
        padding: padding,
        border: border,
        showBorder: border != null,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(Radii.card);
    final fill = color ??
        (elevated
            ? scheme.surfaceContainerHighest
            : theme.cardTheme.color ?? scheme.surface);

    final edge = border ??
        (showBorder
            ? Border.all(color: scheme.outline, width: Sizes.hairline)
            : null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: edge,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}
