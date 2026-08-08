import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One ring: how far round it goes, and in what colour.
class RingSpec {
  final String label;

  /// 0..1. Values above 1 are clamped -- a ring that laps itself reads as less
  /// progress, not more.
  final double progress;
  final Color color;

  const RingSpec({
    required this.label,
    required this.progress,
    required this.color,
  });
}

/// A row of single-day progress rings.
///
/// Deliberately secondary to the hero bar chart above it. Rings answer "where
/// am I right now"; they cannot answer "am I improving", which is what the
/// screen is for -- so they sit under the trend, not instead of it.
class GoalRingRow extends StatelessWidget {
  final List<RingSpec> rings;
  final double diameter;

  const GoalRingRow({
    super.key,
    required this.rings,
    this.diameter = 52,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final ring in rings)
          Column(
            children: [
              SizedBox(
                width: diameter,
                height: diameter,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: ring.progress.clamp(0.0, 1.0),
                    color: ring.color,
                    trackColor: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                  child: Center(
                    child: Text(
                      '${(ring.progress.clamp(0.0, 1.0) * 100).round()}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ring.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      // Twelve o'clock, clockwise -- the direction every ring UI on the
      // platform uses, so it needs no explaining.
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
