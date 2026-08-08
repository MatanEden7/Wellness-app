import 'dart:math' as math;
import 'dart:ui';

import '../../domain/series.dart';

/// Shared axis maths for every painter in this folder.
///
/// The rules the whole screen holds to, so that seven cards read as one
/// system rather than seven charts:
///
///  * no gridlines beyond a single baseline, and no chart border
///  * at most 4 y labels and 5 x labels regardless of range
///  * values are revealed by tapping, never printed on every point
class ChartScale {
  final double minY;
  final double maxY;
  final Rect plot;

  const ChartScale({
    required this.minY,
    required this.maxY,
    required this.plot,
  });

  /// Fits [values] into [plot], padded so the tallest bar never touches the
  /// top edge and a flat series still gets a sensible band instead of a
  /// zero-height one.
  factory ChartScale.forValues(
    Iterable<double> values,
    Rect plot, {
    bool startAtZero = true,
    double headroom = 0.12,
    double? forceMin,
    double? forceMax,
  }) {
    final list = values.toList();
    if (list.isEmpty) {
      return ChartScale(minY: 0, maxY: 1, plot: plot);
    }

    var lo = forceMin ?? list.reduce(math.min);
    var hi = forceMax ?? list.reduce(math.max);
    if (startAtZero && forceMin == null) lo = math.min(0, lo);

    if (hi == lo) {
      // A dead-flat series -- every weigh-in identical, say. Without a band
      // the line would be drawn at an undefined position.
      final pad = hi.abs() < 1 ? 1.0 : hi.abs() * 0.1;
      lo -= pad;
      hi += pad;
    } else {
      hi += (hi - lo) * headroom;
    }

    return ChartScale(minY: lo, maxY: hi, plot: plot);
  }

  double yFor(double value) {
    final span = maxY - minY;
    if (span <= 0) return plot.bottom;
    final t = (value - minY) / span;
    return plot.bottom - t * plot.height;
  }

  /// x for point [index] of [count], centred in its slot.
  double xForIndex(int index, int count) {
    if (count <= 1) return plot.center.dx;
    final slot = plot.width / count;
    return plot.left + slot * index + slot / 2;
  }

  double get slotWidth => plot.width;
}

/// Evenly spaced label positions, capped so a year-long range does not print a
/// label per bar.
List<int> labelIndices(int count, {int max = 5}) {
  if (count <= 0) return const [];
  if (count <= max) return List<int>.generate(count, (i) => i);

  final step = (count - 1) / (max - 1);
  final out = <int>{};
  for (var i = 0; i < max; i++) {
    out.add((i * step).round().clamp(0, count - 1));
  }
  return out.toList()..sort();
}

/// Builds a path through the observed points, breaking at gaps.
///
/// A gap is a real absence -- an unlogged day, a week with no weigh-in -- and
/// drawing straight through it invents data the user never entered.
List<Path> pathsThroughGaps(MetricSeries series, ChartScale scale) {
  final paths = <Path>[];
  Path? current;

  for (var i = 0; i < series.points.length; i++) {
    final value = series.points[i].value;
    if (value == null) {
      current = null;
      continue;
    }
    final offset = Offset(
      scale.xForIndex(i, series.points.length),
      scale.yFor(value),
    );
    if (current == null) {
      current = Path()..moveTo(offset.dx, offset.dy);
      paths.add(current);
    } else {
      current.lineTo(offset.dx, offset.dy);
    }
  }

  return paths;
}
