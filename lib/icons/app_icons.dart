import 'icon_def.dart';

/// Every icon in the app. Add new ones here and to [all], so the angle test
/// checks them.
abstract final class AppIcons {
  /// The mascot's face, tuned by the owner against the comp logo (20 pixels
  /// wide, 21 tall) with the Nekomimi Tuner page. The grid is twice as fine, so
  /// one unit is half a pixel at that size. The fill is the head with both
  /// ears, the shades are the small triangles inside the ears, the lines are
  /// the closed `^ ^` eyes and the thin lines are the small `w` mouth (the
  /// `:3`). Draw the fill in mint and the lines in ground.
  static const nekomimi = IconDef(
    columns: 40,
    rows: 42,
    lineWidth: 3.5,
    thinWidth: 2,
    fills: [
      // Ear tip, down the outer edge, across the bottom, up the other side,
      // with a 45 degree inner edge on each ear and a flat notch between.
      [(0, 0), (13, 13), (27, 13), (40, 0), (40, 42), (0, 42)],
    ],
    shades: [
      // The small triangle inside each ear, in its lower inner corner.
      [(2, 8), (2, 13), (7, 13)],
      [(38, 8), (38, 13), (33, 13)],
    ],
    lines: [
      // Left eye, right eye.
      ((9, 25), (12, 22)),
      ((12, 22), (15, 25)),
      ((25, 25), (28, 22)),
      ((28, 22), (31, 25)),
    ],
    thinLines: [
      // Mouth: a small w, with a raised middle peak.
      ((17, 33), (18, 34)),
      ((18, 34), (20, 32)),
      ((20, 32), (22, 34)),
      ((22, 34), (23, 33)),
    ],
  );

  /// Discover in the rail: a diamond with a dot in the middle.
  static const discover = IconDef(
    fills: [
      [(7, 7), (9, 7), (9, 9), (7, 9)],
    ],
    lines: [
      ((8, 2), (14, 8)),
      ((14, 8), (8, 14)),
      ((8, 14), (2, 8)),
      ((2, 8), (8, 2)),
    ],
  );

  static const all = <String, IconDef>{
    'nekomimi': nekomimi,
    'discover': discover,
  };
}
