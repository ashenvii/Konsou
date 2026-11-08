import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/icons/app_icons.dart';
import 'package:konsou/icons/icon_def.dart';

void main() {
  group('every icon uses only horizontal, vertical and 45 degree lines', () {
    for (final entry in AppIcons.all.entries) {
      test(entry.key, () => expect(entry.value.badEdges(), isEmpty));
    }
  });

  test('every icon declared in app_icons.dart is listed in AppIcons.all', () {
    final declared = RegExp(r'static const \w+ = IconDef\(')
        .allMatches(File('lib/icons/app_icons.dart').readAsStringSync())
        .length;
    expect(AppIcons.all.length, declared);
  });

  group('the check itself', () {
    test('catches a line that is not on an allowed angle', () {
      const bad = IconDef(lines: [((0, 0), (4, 2))]);
      expect(bad.badEdges(), hasLength(1));
    });

    test('catches a fill edge that is not on an allowed angle', () {
      const bad = IconDef(
        fills: [
          [(0, 0), (8, 0), (4, 6)],
        ],
      );
      // Two of the three edges are off angle.
      expect(bad.badEdges(), hasLength(2));
    });

    test('catches a bad edge in a shade or a thin line', () {
      const bad = IconDef(
        shades: [
          [(0, 0), (4, 1), (0, 4)],
        ],
        thinLines: [((0, 0), (5, 2))],
      );
      // Two edges of the shade are off angle, plus the thin line.
      expect(bad.badEdges(), hasLength(3));
    });

    test('catches a zero length line and a point off the grid', () {
      const bad = IconDef(lines: [((3, 3), (3, 3)), ((0, 0), (20, 0))]);
      expect(bad.badEdges(), hasLength(2));
    });

    test('accepts all eight directions', () {
      const ok = IconDef(
        lines: [
          ((8, 8), (8, 2)),
          ((8, 8), (14, 2)),
          ((8, 8), (14, 8)),
          ((8, 8), (14, 14)),
          ((8, 8), (8, 14)),
          ((8, 8), (2, 14)),
          ((8, 8), (2, 8)),
          ((8, 8), (2, 2)),
        ],
      );
      expect(ok.badEdges(), isEmpty);
    });
  });
}
