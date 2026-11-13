import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';

/// Text colors must read at 4.5:1 (WCAG AA) on every fill they can sit on.
void main() {
  final fills = {
    'ground': Tokens.ground,
    'surface': Tokens.surface,
    'raised': Tokens.raised,
  };
  final inks = {
    'ink': Tokens.ink,
    'inkSoft': Tokens.inkSoft,
    'inkMuted': Tokens.inkMuted,
    'amber': Tokens.amber,
    'mint': Tokens.mint,
    'red': Tokens.red,
  };

  for (final ink in inks.entries) {
    for (final fill in fills.entries) {
      test('${ink.key} on ${fill.key} is at least 4.5:1', () {
        expect(_contrast(ink.value, fill.value), greaterThanOrEqualTo(4.5));
      });
    }
  }
}

double _contrast(Color a, Color b) {
  final x = _luminance(a);
  final y = _luminance(b);
  final hi = x > y ? x : y;
  final lo = x > y ? y : x;
  return (hi + 0.05) / (lo + 0.05);
}

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : _pow((v + 0.055) / 1.055, 2.4);
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _pow(double base, double exp) => math.pow(base, exp).toDouble();
