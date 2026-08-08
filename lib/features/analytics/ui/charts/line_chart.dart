import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/series.dart';
import 'chart_geometry.dart';

/// A line with optional dots and a smoothed companion line.
///
/// Two lines is the maximum on purpose: the pairs this screen draws are
/// always "raw plus its smoothing" (weigh-ins with their EMA, top sets with
/// their estimated 1RM), and a third series would need a legend, which the
/// cards have no room for.
class AnalyticsLineChart extends StatefulWidget {
  final MetricSeries series;
  final Color color;

  /// Drawn thinner and dimmer beneath [series]. Null when there is nothing to
  /// compare against.
  final MetricSeries? raw;
  final Color? rawColor;

  /// Dots on every observation of [series]. Off for dense ranges, where a dot
  /// per point turns the line into a caterpillar.
  final bool showDots;

  /// Fills below the line. Off by default -- a filled area exaggerates small
  /// changes, which is the wrong instinct for body weight.
  final bool fill;

  final bool startAtZero;
  final double height;
  final ValueChanged<int?>? onSelectionChanged;
  final int? selectedIndex;

  const AnalyticsLineChart({
    super.key,
    required this.series,
    required this.color,
    this.raw,
    this.rawColor,
    this.showDots = true,
    this.fill = false,
    this.startAtZero = false,
    this.height = 120,
    this.onSelectionChanged,
    this.selectedIndex,
  });

  @override
  State<AnalyticsLineChart> createState() => _AnalyticsLineChartState();
}

class _AnalyticsLineChartState extends State<AnalyticsLineChart> {
  int? _lastReported;

  void _updateSelection(Offset localPosition, Size size) {
    final count = widget.series.points.length;
    if (count == 0) return;
    final slot = size.width / count;
    final index = (localPosition.dx / slot).floor().clamp(0, count - 1);
    if (index == _lastReported) return;
    _lastReported = index;
    HapticFeedback.selectionClick();
    widget.onSelectionChanged?.call(index);
  }

  void _clear() {
    _lastReported = null;
    widget.onSelectionChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, widget.height);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _updateSelection(d.localPosition, size),
            onTapUp: (_) => _clear(),
            onTapCancel: _clear,
            onHorizontalDragStart: (d) =>
                _updateSelection(d.localPosition, size),
            onHorizontalDragUpdate: (d) =>
                _updateSelection(d.localPosition, size),
            onHorizontalDragEnd: (_) => _clear(),
            onHorizontalDragCancel: _clear,
            child: CustomPaint(
              size: size,
              painter: _LineChartPainter(
                series: widget.series,
                raw: widget.raw,
                color: widget.color,
                rawColor: widget.rawColor ??
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ??
                    theme.dividerColor,
                baselineColor: theme.dividerColor,
                selectionColor: theme.colorScheme.onSurface,
                surfaceColor: theme.colorScheme.surface,
                showDots: widget.showDots,
                fill: widget.fill,
                startAtZero: widget.startAtZero,
                selectedIndex: widget.selectedIndex,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final MetricSeries series;
  final MetricSeries? raw;
  final Color color;
  final Color rawColor;
  final Color baselineColor;
  final Color selectionColor;
  final Color surfaceColor;
  final bool showDots;
  final bool fill;
  final bool startAtZero;
  final int? selectedIndex;

  _LineChartPainter({
    required this.series,
    required this.raw,
    required this.color,
    required this.rawColor,
    required this.baselineColor,
    required this.selectionColor,
    required this.surfaceColor,
    required this.showDots,
    required this.fill,
    required this.startAtZero,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    // 4pt inset top and bottom so dots and the stroke are not clipped in half
    // against the card edge.
    final plot = Rect.fromLTWH(0, 4, size.width, size.height - 9);
    final scale = ChartScale.forValues(
      [...series.values, ...?raw?.values],
      plot,
      startAtZero: startAtZero,
      headroom: 0.08,
    );

    if (fill) _paintFill(canvas, scale, plot);

    final rawSeries = raw;
    if (rawSeries != null && rawSeries.isNotEmpty) {
      _paintDots(canvas, rawSeries, scale, rawColor, 2.0);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final path in pathsThroughGaps(series, scale)) {
      canvas.drawPath(path, linePaint);
    }

    // A lone observation between two gaps produces a path with no segments and
    // would draw nothing at all, so every point also gets a dot when dots are
    // on -- otherwise a single weigh-in renders as an empty card.
    if (showDots) _paintDots(canvas, series, scale, color, 2.5, ring: true);

    _paintSelection(canvas, scale, size);

    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = baselineColor
        ..strokeWidth = 1,
    );
  }

  void _paintFill(Canvas canvas, ChartScale scale, Rect plot) {
    for (final path in pathsThroughGaps(series, scale)) {
      final bounds = path.getBounds();
      if (bounds.width <= 0) continue;
      final filled = Path.from(path)
        ..lineTo(bounds.right, plot.bottom)
        ..lineTo(bounds.left, plot.bottom)
        ..close();
      canvas.drawPath(filled, Paint()..color = color.withValues(alpha: 0.10));
    }
  }

  void _paintDots(
    Canvas canvas,
    MetricSeries source,
    ChartScale scale,
    Color dotColor,
    double radius, {
    bool ring = false,
  }) {
    final count = source.points.length;
    // Past ~60 points a dot per observation reads as a thick smudge, so they
    // are dropped and the line carries the shape on its own.
    if (count > 60) return;

    for (var i = 0; i < count; i++) {
      final value = source.points[i].value;
      if (value == null) continue;
      final center = Offset(scale.xForIndex(i, count), scale.yFor(value));
      if (ring) {
        canvas.drawCircle(center, radius + 1, Paint()..color = surfaceColor);
      }
      canvas.drawCircle(center, radius, Paint()..color = dotColor);
    }
  }

  void _paintSelection(Canvas canvas, ChartScale scale, Size size) {
    final index = selectedIndex;
    if (index == null || index < 0 || index >= series.points.length) return;

    final x = scale.xForIndex(index, series.points.length);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = selectionColor.withValues(alpha: 0.28)
        ..strokeWidth = 1,
    );

    final value = series.points[index].value;
    if (value == null) return;
    canvas.drawCircle(
      Offset(x, scale.yFor(value)),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.series != series ||
      old.raw != raw ||
      old.selectedIndex != selectedIndex ||
      old.color != color;
}
