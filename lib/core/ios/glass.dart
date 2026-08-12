import 'dart:ui';

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'pressable.dart';

/// The Liquid Glass material, as far as Flutter can express it.
///
/// iOS 26 hands real Liquid Glass to UIKit and SwiftUI views. Flutter paints
/// its own canvas and never receives it, so everything here is a *recipe* for
/// the same effect: blur the backdrop, push its saturation up, lay a tint of
/// the theme's own surface colour over it, and light the top rim. The
/// saturation step is what separates glass from frosted plastic — it pulls the
/// colour out of the blurred backdrop instead of averaging it to grey.
///
/// The genuine article is still ahead of this on two counts: edge refraction
/// (real glass bends content at its curved rim) and the gyroscope-tracked
/// highlight. Both need a fragment shader sampling the full screen every
/// frame, which is not worth it for surfaces that are on screen constantly.
///
/// The native nav bar and tab bar are *not* drawn from this file. They are
/// UIKit and get the real material from `configureWithDefaultBackground()`.

// ─── Level ───────────────────────────────────────────────────────────────────

/// How much glass the user wants. Stored as a preference; forced to [off] when
/// the system reports Reduce Transparency.
enum GlassLevel {
  /// Solid surfaces — byte-for-byte the pre-glass look.
  off,

  /// Enough translucency to read as glass, weighted towards legibility.
  subtle,

  /// The full material.
  full,
}

// ─── Spec ────────────────────────────────────────────────────────────────────

/// A resolved glass recipe. Carries no colours: the tint is derived from the
/// ambient theme at paint time, which is what keeps glass looking like *this*
/// app in all nine themes rather than like a grey film laid over them.
@immutable
class GlassSpec {
  const GlassSpec({
    required this.blurSigma,
    required this.saturation,
    required this.tintAlpha,
    required this.edgeAlpha,
    required this.borderAlpha,
    required this.prominentTintAlpha,
  });

  /// Gaussian blur applied to the backdrop.
  final double blurSigma;

  /// Saturation multiplier applied after the blur. 1.0 leaves colour alone.
  final double saturation;

  /// Opacity of the surface tint. Higher = more legible, less glassy.
  ///
  /// The floor is set by `theme_contrast_test`, which composites the tint over
  /// both the scaffold colour and the strongest stop of the page wash.
  ///
  /// Note that our panes and the native bars are deliberately *not* the same
  /// material: UIKit renders the system's, we render a clearer one. Matching
  /// them was tried and reverted — see the note in `glass_surface_test.dart`.
  ///
  /// What that test does **not** bound is arbitrary content passing behind a
  /// pane — a card scrolling under another card. The blur is what protects
  /// legibility there, which is why `full` also carries the largest sigma.
  final double tintAlpha;

  /// Opacity of the specular highlight along the top rim.
  final double edgeAlpha;

  /// Opacity of the hairline border.
  final double borderAlpha;

  /// Tint opacity for a *prominent* control — a primary action button.
  ///
  /// Much higher than [tintAlpha] and deliberately so. A card's job is to hold
  /// legible text over an unknown backdrop; a primary button's job is to be the
  /// obvious next tap, and a translucent accent over a light background stops
  /// being obvious well before it stops being pretty. `theme_contrast_test`
  /// pins this the same way it pins [tintAlpha] — 0.86 read well but put
  /// Forest, Sunset and Lavender under 4.5:1 for their button labels, which is
  /// how 0.93 was arrived at rather than by eye.
  final double prominentTintAlpha;

  /// Solid surfaces. Every widget in the kit falls back to this shape, so
  /// "glass off" is a real code path rather than a special case.
  static const none = GlassSpec(
    blurSigma: 0,
    saturation: 1,
    tintAlpha: 1,
    edgeAlpha: 0,
    borderAlpha: 0.10,
    prominentTintAlpha: 1,
  );

  bool get enabled => blurSigma > 0;

  /// The recipe for [level].
  ///
  /// `full` is a *clear* glass rather than a frosted one: a whisper of tint
  /// over a narrow blur, so what is behind stays recognisable instead of being
  /// smeared into a wash of colour. Apple ships the same two flavours — a
  /// regular material that hides what is behind it, and a clear one for places
  /// where the content underneath is worth seeing.
  ///
  /// The trade-off is legibility, and it is real: with both numbers this low,
  /// neither the tint nor the blur is protecting the label over busy content.
  /// `subtle` is the version that does — more tint, and enough blur to stop the
  /// backdrop competing.
  factory GlassSpec.resolve(GlassLevel level) => switch (level) {
        GlassLevel.off => none,
        GlassLevel.subtle => const GlassSpec(
            blurSigma: 11,
            saturation: 1.25,
            tintAlpha: 0.34,
            edgeAlpha: 0.28,
            borderAlpha: 0.12,
            prominentTintAlpha: 0.94,
          ),
        GlassLevel.full => const GlassSpec(
            // Barely any blur. Past a certain point the blur is what stops you
            // reading what is behind the pane, and "I want to see what is
            // behind it" is a request to turn it down, not up.
            blurSigma: 7,
            // Which moves the work of *looking* like glass onto the other three
            // numbers: the saturation boost that makes the backdrop's colour
            // pop through, the lit top rim, and the edge. A pane this clear is
            // defined by its rim, not by its fill.
            saturation: 1.8,
            tintAlpha: 0.07,
            edgeAlpha: 0.55,
            borderAlpha: 0.24,
            prominentTintAlpha: 0.92,
          ),
      };

  /// The colour actually painted over the blurred backdrop.
  ///
  /// The theme's **elevated** step, not `surface`.
  ///
  /// Glass is the layer that floats above content, so its tint should read as
  /// the rung above whatever it covers — a bar tinted with the same colour as
  /// the cards under it has no depth to express. Deliberately the theme's own
  /// colour rather than white or black: it keeps each theme's identity, and it
  /// makes the contrast argument provable, since `theme_contrast_test` pins
  /// `onSurface` against both ends of the ramp.
  Color tint(ColorScheme scheme) =>
      scheme.surfaceContainerHighest.withValues(alpha: enabled ? tintAlpha : 1);

  /// The tint for a prominent control: the theme's accent, barely translucent.
  Color prominentTint(ColorScheme scheme) =>
      scheme.primary.withValues(alpha: enabled ? prominentTintAlpha : 1);

  /// What the surface composites to over [background]. Used by the contrast
  /// test, and by callers that need an opaque approximation (shadows, painters).
  Color composite(ColorScheme scheme, Color background) =>
      Color.alphaBlend(tint(scheme), background);

  ImageFilter get imageFilter => saturation == 1
      ? ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma)
      : ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          inner: ColorFilter.matrix(saturationMatrix(saturation)),
        );

  /// Saturation as a 4x5 colour matrix, using the standard luminance
  /// coefficients so a grey stays grey at any multiplier.
  static List<double> saturationMatrix(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final ir = (1 - s) * lr, ig = (1 - s) * lg, ib = (1 - s) * lb;
    return <double>[
      ir + s, ig, ib, 0, 0, //
      ir, ig + s, ib, 0, 0, //
      ir, ig, ib + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is GlassSpec &&
      other.blurSigma == blurSigma &&
      other.saturation == saturation &&
      other.tintAlpha == tintAlpha &&
      other.edgeAlpha == edgeAlpha &&
      other.borderAlpha == borderAlpha &&
      other.prominentTintAlpha == prominentTintAlpha;

  @override
  int get hashCode => Object.hash(blurSigma, saturation, tintAlpha, edgeAlpha,
      borderAlpha, prominentTintAlpha);
}

// ─── Ambient spec ────────────────────────────────────────────────────────────

/// Carries the active [GlassSpec] down the tree.
///
/// An `InheritedWidget` rather than a Riverpod provider on purpose: every
/// widget that reads it lives in `lib/core/`, which has no Riverpod dependency
/// and should keep none. It also means a widget test can pump a glass surface
/// without a `ProviderScope`.
class GlassTheme extends InheritedWidget {
  const GlassTheme({super.key, required this.spec, required super.child});

  final GlassSpec spec;

  /// The ambient spec, or [GlassSpec.none] when no [GlassTheme] is installed —
  /// which is the case on Android and in most tests, and is why nothing
  /// outside iOS changes appearance.
  static GlassSpec of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassTheme>()?.spec ??
      GlassSpec.none;

  @override
  bool updateShouldNotify(GlassTheme old) => old.spec != spec;
}

// ─── Surface ─────────────────────────────────────────────────────────────────

/// One pane of glass: the single place the material is painted.
///
/// Every card, list group, sheet and bar in the app goes through this. When
/// glass is off it collapses to a plain tinted box with the same geometry, so
/// the two states differ only in material.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.fallbackColor,
    this.showBorder = true,
    this.showEdgeHighlight = true,
    this.tintOverride,
    this.border,
  });

  /// A glass pane tinted with an accent instead of the theme surface — the
  /// shape every badge, chip, pill and status banner in the app already had as
  /// `BoxDecoration(color: accent.withValues(alpha: …))`.
  ///
  /// Passing the *same* colour as both tint and fallback is what makes the
  /// conversion safe: with glass off the pane is byte-identical to the
  /// `Container` it replaced, and with glass on that colour is laid over the
  /// blurred backdrop instead of over a flat one.
  factory GlassSurface.tinted({
    Key? key,
    required Color color,
    required Widget child,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    BoxBorder? border,
    bool showEdgeHighlight = false,
  }) =>
      GlassSurface(
        key: key,
        borderRadius: borderRadius,
        padding: padding,
        fallbackColor: color,
        tintOverride: color,
        border: border,
        showBorder: border != null,
        showEdgeHighlight: showEdgeHighlight,
        child: child,
      );

  final Widget child;

  /// Defaults to [Radii.card]. A surface nested inside another should use
  /// [Radii.inner] against its parent rather than picking a number.
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Colour used when glass is off. Defaults to the theme's card colour.
  final Color? fallbackColor;

  final bool showBorder;

  /// The specular highlight along the top rim. Off for tall surfaces where a
  /// lit top edge would read as a seam rather than as a lit surface.
  final bool showEdgeHighlight;

  /// Replaces the theme-surface tint — an accent for a button or a badge.
  /// Prefer [GlassSurface.tinted], which sets this and [fallbackColor]
  /// together so the two states cannot drift apart.
  final Color? tintOverride;

  /// Replaces the default hairline. For panes that carried a specific border
  /// before conversion (a status banner outlined in its own accent).
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spec = GlassTheme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(Radii.card);
    final edge = this.border ??
        (showBorder
            ? Border.all(
                color: scheme.onSurface.withValues(alpha: spec.borderAlpha),
                width: 0.5,
              )
            : null);

    if (!spec.enabled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fallbackColor ?? theme.cardTheme.color ?? scheme.surface,
          borderRadius: radius,
          border: border,
        ),
        child:
            padding == null ? child : Padding(padding: padding!, child: child),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      // `.grouped`, never the plain constructor: it joins the nearest
      // BackdropGroup so the engine reads the backdrop once for the whole
      // screen instead of once per card. A page with a dozen glass cards is
      // only affordable because of this.
      child: BackdropFilter.grouped(
        filter: spec.imageFilter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tintOverride ?? spec.tint(scheme),
            borderRadius: radius,
            border: edge,
          ),
          child: Stack(
            children: [
              if (showEdgeHighlight)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        // A single hairline reads as a border; a short gradient
                        // reads as light catching a lit surface.
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: spec.edgeAlpha),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [0.0, 0.22],
                        ),
                      ),
                    ),
                  ),
                ),
              padding == null
                  ? child
                  : Padding(padding: padding!, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page layer ──────────────────────────────────────────────────────────────

/// What a page's body is wrapped in: the backdrop underneath, and one
/// [BackdropGroup] around everything above it.
///
/// The group is the load-bearing part. Every [GlassSurface] uses
/// `BackdropFilter.grouped`, which looks up the nearest group and shares its
/// backdrop read — so a screen with a dozen glass cards costs the engine one
/// read rather than twelve. A glass surface rendered *outside* any group still
/// works and still looks right, which is exactly why this is easy to get wrong:
/// the only symptom is raster time.
///
/// One group per route, not per app: the framework renders overlapping filters
/// that share a key as though only one of them applied, and a modal floating
/// over a page overlaps it by definition. Modals bring their own.
class GlassLayer extends StatelessWidget {
  const GlassLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(child: GlassBackdrop()),
          BackdropGroup(child: child),
        ],
      );
}

// ─── Button ──────────────────────────────────────────────────────────────────

/// A button rendered as a pane of glass.
///
/// Two weights, and the distinction is the whole design:
///
///  * **prominent** — the one action the screen exists for. Tinted with the
///    theme's accent at [GlassSpec.prominentTintAlpha], which is high: a
///    primary action that has gone translucent enough to blend into the page
///    has stopped doing its job. Labelled `onPrimary`.
///  * **plain** — everything else. The same surface tint the cards use, with
///    the label in the accent colour, the way an iOS button reads.
///
/// When glass is off both collapse to the solid fill they had before, so the
/// Off setting really is the old build.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.prominent = false,
    this.tint,
    this.padding,
    this.minHeight = Sizes.controlLarge,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool prominent;

  /// Overrides the accent for a prominent button — a destructive red, or a
  /// section colour on the dashboard.
  final Color? tint;

  final EdgeInsetsGeometry? padding;

  /// Apple's large-control height. A capsule at this height has a 25pt radius,
  /// which is where [borderRadius]'s default comes from.
  final double minHeight;

  final BorderRadius? borderRadius;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spec = GlassTheme.of(context);
    // A capsule at this height, per Apple: large controls are capsules, and a
    // capsule stays concentric inside any parent for free.
    final radius =
        borderRadius ?? BorderRadius.circular(Radii.capsule(minHeight));
    final accent = tint ?? scheme.primary;

    final fill = prominent
        ? accent.withValues(alpha: spec.enabled ? spec.prominentTintAlpha : 1)
        : spec.tint(scheme);
    final label = prominent ? scheme.onPrimary : accent;

    Widget content = Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.md),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: label,
          fontSize: 17,
          fontWeight: prominent ? FontWeight.w600 : FontWeight.w500,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: label, size: 18),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );

    content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: content,
    );

    // Disabled state is opacity rather than a separate colour ramp: the fill
    // is already a blend of the accent and whatever is behind it, so a second
    // set of "disabled" colours would fight it.
    final pane = Opacity(
      opacity: _enabled ? 1 : 0.4,
      child: GlassSurface(
        borderRadius: radius,
        fallbackColor: fill,
        // A prominent button is its own accent block; a rim highlight on top
        // of that reads as a gradient, not as glass.
        showEdgeHighlight: !prominent,
        showBorder: !prominent,
        tintOverride: fill,
        child: content,
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      // Every button in the app funnels through here, so the ripple that used
      // to live on this line was the app's most-repeated Android tell. iOS
      // dims a pressed button and taps a light impact against it.
      child: Pressable(
        onTap: onPressed,
        borderRadius: radius,
        haptic: HapticKind.light,
        child: pane,
      ),
    );
  }
}

// ─── Sheet surface ───────────────────────────────────────────────────────────

/// The pane a modal bottom sheet sits on.
///
/// Its own [BackdropGroup], not the page's: a sheet floats *over* the page it
/// was opened from, and the framework renders overlapping backdrop filters
/// that share a key as though only one of them applied.
///
/// Pair with `backgroundColor: Colors.transparent` on the `showModalBottomSheet`
/// call — a colour there paints on top of the blur and hides it.
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child, this.radius = Radii.sheet});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => BackdropGroup(
        child: GlassSurface(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          showBorder: false,
          fallbackColor: Theme.of(context).colorScheme.surface,
          child: child,
        ),
      );
}

// ─── Backdrop ────────────────────────────────────────────────────────────────

/// The layer that makes glass worth having.
///
/// Blurring a flat colour returns the same flat colour, so glass over the old
/// single-colour scaffold background would have been invisible. This paints a
/// soft wash derived from the active theme — no animation, no shader, one
/// gradient — so there is colour for the surfaces above it to pick up and
/// refract as they scroll.
///
/// Falls back to the plain scaffold colour when glass is off, which is exactly
/// what the scaffold painted before.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.scaffoldBackgroundColor;
    final spec = GlassTheme.of(context);

    if (!spec.enabled) return ColoredBox(color: base);

    // Alpha-blended into the base rather than layered translucently: the wash
    // must stay opaque, or the surfaces above would blur straight through to
    // whatever the OS put behind the Flutter view.
    Color wash(Color c, double alpha) =>
        Color.alphaBlend(c.withValues(alpha: alpha), base);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            wash(scheme.primary, 0.20),
            base,
            wash(scheme.tertiary, 0.16),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
