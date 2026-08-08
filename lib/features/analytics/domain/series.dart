import 'dart:math' as math;

/// One point on a dated series.
///
/// [value] is nullable and null means **no data**, not zero. The distinction
/// matters in both directions: a day with no meals logged must not pull the
/// average down as a 0-kcal day, and a chart must draw a gap there rather than
/// a line through the floor.
class TimeSeriesPoint {
  final DateTime t;
  final double? value;

  const TimeSeriesPoint(this.t, this.value);

  bool get hasValue => value != null;
}

/// A dated series, oldest first.
class MetricSeries {
  final List<TimeSeriesPoint> points;

  const MetricSeries(this.points);

  const MetricSeries.empty() : points = const [];

  bool get isEmpty => points.every((p) => !p.hasValue);
  bool get isNotEmpty => !isEmpty;

  Iterable<double> get values =>
      points.where((p) => p.hasValue).map((p) => p.value!);

  int get observedCount => values.length;

  double? get average {
    final v = values.toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b) / v.length;
  }

  double? get total {
    final v = values.toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b);
  }

  double? get min => values.isEmpty ? null : values.reduce(math.min);
  double? get max => values.isEmpty ? null : values.reduce(math.max);

  double? get latest {
    for (final p in points.reversed) {
      if (p.hasValue) return p.value;
    }
    return null;
  }

  double? get earliest {
    for (final p in points) {
      if (p.hasValue) return p.value;
    }
    return null;
  }

  /// Centred-on-the-right moving average over the last [window] observations.
  ///
  /// Gaps are skipped rather than treated as zero, and a point stays null
  /// until at least two observations exist behind it -- a "7-day average"
  /// computed from one day is just that day wearing a disguise.
  MetricSeries movingAverage(int window) {
    final out = <TimeSeriesPoint>[];
    for (var i = 0; i < points.length; i++) {
      final from = math.max(0, i - window + 1);
      final slice = points
          .sublist(from, i + 1)
          .where((p) => p.hasValue)
          .map((p) => p.value!)
          .toList();
      out.add(TimeSeriesPoint(
        points[i].t,
        slice.length < 2 ? null : slice.reduce((a, b) => a + b) / slice.length,
      ));
    }
    return MetricSeries(out);
  }

  /// Exponential moving average with smoothing factor [alpha] (0..1).
  ///
  /// Used for body weight, where day-to-day movement is mostly water and the
  /// raw line invites the wrong conclusion in both directions.
  MetricSeries exponentialMovingAverage(double alpha) {
    double? acc;
    final out = <TimeSeriesPoint>[];
    for (final p in points) {
      if (p.hasValue) {
        acc = acc == null ? p.value! : alpha * p.value! + (1 - alpha) * acc;
      }
      out.add(TimeSeriesPoint(p.t, acc));
    }
    return MetricSeries(out);
  }

  /// Least-squares slope in units per day, or null with fewer than two
  /// observations. Positive means rising.
  double? get slopePerDay {
    final observed = points.where((p) => p.hasValue).toList();
    if (observed.length < 2) return null;

    final t0 = observed.first.t;
    var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumXX = 0.0;
    for (final p in observed) {
      final x = p.t.difference(t0).inMinutes / (60 * 24);
      final y = p.value!;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    final n = observed.length;
    final denominator = n * sumXX - sumX * sumX;
    if (denominator == 0) return null;
    return (n * sumXY - sumX * sumY) / denominator;
  }

  /// Mean of the last [n] observations, ignoring gaps.
  double? tailAverage(int n) {
    final v = values.toList();
    if (v.isEmpty) return null;
    final slice = v.sublist(math.max(0, v.length - n));
    return slice.reduce((a, b) => a + b) / slice.length;
  }
}

/// Population standard deviation, or null with fewer than two samples.
double? standardDeviation(List<double> samples) {
  if (samples.length < 2) return null;
  final mean = samples.reduce((a, b) => a + b) / samples.length;
  final variance =
      samples.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) /
          samples.length;
  return math.sqrt(variance);
}
