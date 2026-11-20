import 'dart:math' as math;
import 'dart:ui';

/// [source] cut into dashes of [dash] with [gap] between them.
Path dashedPath(Path source, double dash, double gap) {
  final dashed = Path();
  for (final metric in source.computeMetrics()) {
    for (var at = 0.0; at < metric.length; at += dash + gap) {
      dashed.addPath(
        metric.extractPath(at, math.min(at + dash, metric.length)),
        Offset.zero,
      );
    }
  }
  return dashed;
}
