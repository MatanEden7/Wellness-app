import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/series.dart';
import 'chart_geometry.dart';

/// One coloured slice of a bar. A plain bar is a single segment.
class BarSegment {
  final double value;
  final Color color;

  const BarSegment(this.value, this.color);
}

/// One bar: its stacked segments, bottom-first, and the day it represents.
class BarDatum {
  final DateTime t;
  final List<BarSegment> segments;

  const BarDatum(this.t, this.segments);

  double get total => segments.fold(0.0, (sum, s) => sum + s.value);

  bool get isEmpty => segments.isEmpty || total <= 0;
}

/// A horizontal reference line, optionally with a tolerance band around it.
///
/// This is how a goal is drawn: a dashed line at the target with the band that
/// still counts as hitting it, so "close enough" is visible rather than
/// something the user has to infer.
class GoalMarker {
  final double value;
  final double? bandLow;
  final double? bandHigh;

  const GoalMarker(this.value, {this.bandLow, this.bandHigh});
}

/// Bars, optionally stacked, with an optional goal marker and trend overlay.
///
/// Scrubbing: touch and drag reveals the value for one bar and a haptic ticks
/// as the selection moves. Nothing is labelled permanently -- that is what
/// keeps a 30-bar chart readable at 393pt wide.
class AnalyticsBarChart extends StatefulWidget {
  final List<BarDatum> bars;
  final GoalMarker? goal;

  /// Drawn over the bars. Used for the 7-day calorie average, which is what
  /// makes a trend visible through day-to-day spikiness.
  final MetricSeries? overlay;
  final Color? overlayColor;

  final double height;

  /// Forces the top of the scale. Used by the goal chart, where the axis is
  /// 0..1 by definition and must not rescale as the data changes.
  final double? maxY;

  /// Called with the scrubbed bar index, or null when the touch is released.
  final ValueChanged<int?>? onSelectionChanged;

  final int? selectedIndex;

  const AnalyticsBarChart({
    super.key,
    required this.bars,
    this.goal,
    this.overlay,
    this.overlayColor,
    this.height = 120,
    this.maxY,
    this.onSelectionChanged,
    this.selectedIndex,
  });

  @override
  State<AnalyticsBarChart> createState() => _AnalyticsBarChartState();
}

class _AnalyticsBarChartState extends State<AnalyticsBarChart> {
  int? _lastReported;

  void _updateSelection(Offset localPosition, Size size) {
    if (widget.bars.isEmpty) return;
    final slot = size.width / widget.bars.length;
    final index =
        (localPosition.dx / slot).floor().clamp(0, widget.bars.length - 1);
    if (index == _lastReported) return;
    _lastReported = index;
    HapticFeedback.selectionClick();
    widget.onSelectionChanged?.call(index);
  }

  void _clearSelection() {
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
            onTapUp: (_) => _clearSelection(),
            onTapCancel: _clearSelection,
            onHorizontalDragStart: (d) =>
                _updateSelection(d.localPosition, size),
            onHorizontalDragUpdate: (d) =>
                _updateSelection(d.localPosition, size),
            onHorizontalDragEnd: (_) => _clearSelection(),
            onHorizontalDragCancel: _clearSelection,
            child: CustomPaint(
              size: size,
              painter: _BarChartPainter(
                bars: widget.bars,
                goal: widget.goal,
                overlay: widget.overlay,
                overlayColor: widget.overlayColor ?? theme.colorScheme.primary,
                baselineColor: theme.dividerColor,
                goalLineColor: theme.textTheme.bodySmall?.color ??
                    theme.colorScheme.onSurface,
                selectionColor: theme.colorScheme.onSurface,
                emptyColor: theme.dividerColor.withValues(alpha: 0.35),
                maxY: widget.maxY,
                selectedIndex: widget.selectedIndex,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<BarDatum> bars;
  final GoalMarker? goal;
  final MetricSeries? overlay;
  final Color overlayColor;
  final Color baselineColor;
  final Color goalLineColor;
  final Color selectionColor;
  final Color emptyColor;
  final double? maxY;
  final int? selectedIndex;

  _BarChartPainter({
    required this.bars,
    required this.goal,
    required this.overlay,
    required this.overlayColor,
    required this.baselineColor,
    required this.goalLineColor,
    required this.selectionColor,
    required this.emptyColor,
    required this.maxY,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    // One hairline of headroom at the bottom for the baseline itself.
    final plot = Rect.fromLTWH(0, 0, size.width, size.height - 1);

    final candidates = <double>[
      ...bars.map((b) => b.total),
      if (goal != null) goal!.value,
      if (goal?.bandHigh != null) goal!.bandHigh!,
      ...?overlay?.values,
    ];

    final scale = ChartScale.forValues(
      candidates,
      plot,
      forceMax: maxY,
      forceMin: maxY == null ? null : 0,
    );

    _paintGoalBand(canvas, scale);
    _paintBars(canvas, scale);
    _paintGoalLine(canvas, scale, size);
    _paintOverlay(canvas, scale);
    _paintSelection(canvas, scale, size);

    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = baselineColor
        ..strokeWidth = 1,
    );
  }

  void _paintGoalBand(Canvas canvas, ChartScale scale) {
    final marker = goal;
    if (marker?.bandLow == null || marker?.bandHigh == null) return;

    final top = scale.yFor(marker!.bandHigh!);
    final bottom = scale.yFor(marker.bandLow!);
    canvas.drawRect(
      Rect.fromLTRB(scale.plot.left, top, scale.plot.right, bottom),
      Paint()..color = goalLineColor.withValues(alpha: 0.06),
    );
  }

  void _paintBars(Canvas canvas, ChartScale scale) {
    final slot = scale.plot.width / bars.length;
    // Bars stay at least 2pt wide and never wider than 14pt: below 2 they
    // disappear on a year view, above 14 a seven-bar week looks like a
    // different chart entirely.
    final barWidth = (slot * 0.62).clamp(2.0, 14.0);
    final radius = Radius.circular(barWidth / 2.5);
    final zero = scale.yFor(0);

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final centerX = scale.plot.left + slot * i + slot / 2;
      final left = centerX - barWidth / 2;

      if (bar.isEmpty) {
        // A 2pt stub, not nothing: an unlogged day should read as "no data
        // here" rather than as an invisible hole in the axis.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, zero - 2, barWidth, 2),
            const Radius.circular(1),
          ),
          Paint()..color = emptyColor,
        );
        continue;
      }

      var cursor = 0.0;
      for (final segment in bar.segments) {
        if (segment.value <= 0) continue;
        final top = scale.yFor(cursor + segment.value);
        final bottom = scale.yFor(cursor);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, left + barWidth, bottom),
            radius,
          ),
          Paint()..color = segment.color,
        );
        cursor += segment.value;
      }
    }
  }

  void _paintGoalLine(Canvas canvas, ChartScale scale, Size size) {
    final marker = goal;
    if (marker == null) return;

    final y = scale.yFor(marker.value);
    final paint = Paint()
      ..color = goalLineColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    // Hand-drawn dashes: Flutter has no dashed-stroke primitive and a package
    // for one line is not worth a dependency.
    const dash = 4.0;
    const gap = 4.0;
    var x = scale.plot.left;
    while (x < scale.plot.right) {
      canvas.drawLine(
          Offset(x, y), Offset((x + dash).clamp(0.0, size.width), y), paint);
      x += dash + gap;
    }
  }

  void _paintOverlay(Canvas canvas, ChartScale scale) {
    final series = overlay;
    if (series == null || series.isEmpty) return;

    final paint = Paint()
      ..color = overlayColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final path in pathsThroughGaps(series, scale)) {
      canvas.drawPath(path, paint);
    }
  }

  void _paintSelection(Canvas canvas, ChartScale scale, Size size) {
    final index = selectedIndex;
    if (index == null || index < 0 || index >= bars.length) return;

    final slot = scale.plot.width / bars.length;
    final x = scale.plot.left + slot * index + slot / 2;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = selectionColor.withValues(alpha: 0.28)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.bars != bars ||
      old.selectedIndex != selectedIndex ||
      old.overlay != overlay ||
      old.goal != goal ||
      old.maxY != maxY;
}
