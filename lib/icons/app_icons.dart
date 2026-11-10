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

  /// Library in the rail: four squares in a grid.
  static const library = IconDef(
    lines: [
      ((2, 2), (7, 2)),
      ((7, 2), (7, 7)),
      ((7, 7), (2, 7)),
      ((2, 7), (2, 2)),
      ((9, 2), (14, 2)),
      ((14, 2), (14, 7)),
      ((14, 7), (9, 7)),
      ((9, 7), (9, 2)),
      ((2, 9), (7, 9)),
      ((7, 9), (7, 14)),
      ((7, 14), (2, 14)),
      ((2, 14), (2, 9)),
      ((9, 9), (14, 9)),
      ((14, 9), (14, 14)),
      ((14, 14), (9, 14)),
      ((9, 14), (9, 9)),
    ],
  );

  /// Watching in the rail: a play triangle, set right so its weight, not its
  /// box, sits in the middle.
  static const watching = IconDef(
    lines: [((6, 2), (6, 14)), ((6, 2), (12, 8)), ((12, 8), (6, 14))],
  );

  /// Schedule in the rail: a calendar with two rings.
  static const schedule = IconDef(
    lines: [
      ((2, 3), (14, 3)),
      ((14, 3), (14, 14)),
      ((14, 14), (2, 14)),
      ((2, 14), (2, 3)),
      ((2, 6), (14, 6)),
      ((5, 1), (5, 4)),
      ((11, 1), (11, 4)),
    ],
  );

  /// Settings in the rail: three sliders, each with a square knob.
  static const settings = IconDef(
    fills: [
      [(9, 2), (11, 2), (11, 4), (9, 4)],
      [(4, 7), (6, 7), (6, 9), (4, 9)],
      [(10, 12), (12, 12), (12, 14), (10, 14)],
    ],
    lines: [((2, 3), (14, 3)), ((2, 8), (14, 8)), ((2, 13), (14, 13))],
  );

  /// Grid view: four solid squares.
  static const grid = IconDef(
    fills: [
      [(2, 2), (7, 2), (7, 7), (2, 7)],
      [(9, 2), (14, 2), (14, 7), (9, 7)],
      [(2, 9), (7, 9), (7, 14), (2, 14)],
      [(9, 9), (14, 9), (14, 14), (9, 14)],
    ],
  );

  /// List view: three rows, each a dot and a line.
  static const list = IconDef(
    fills: [
      [(2, 2), (4, 2), (4, 4), (2, 4)],
      [(2, 7), (4, 7), (4, 9), (2, 9)],
      [(2, 12), (4, 12), (4, 14), (2, 14)],
    ],
    lines: [((6, 3), (14, 3)), ((6, 8), (14, 8)), ((6, 13), (14, 13))],
  );

  /// Opens a menu.
  static const chevronDown = IconDef(
    lines: [((3, 6), (8, 11)), ((8, 11), (13, 6))],
  );

  /// The Completed mark, and a checked box.
  static const check = IconDef(lines: [((3, 8), (6, 11)), ((6, 11), (13, 4))]);

  /// The three dots that open an entry's menu.
  static const more = IconDef(
    fills: [
      [(7, 2), (9, 2), (9, 4), (7, 4)],
      [(7, 7), (9, 7), (9, 9), (7, 9)],
      [(7, 12), (9, 12), (9, 14), (7, 14)],
    ],
  );

  /// Planned: a bookmark.
  static const planned = IconDef(
    lines: [
      ((4, 2), (12, 2)),
      ((12, 2), (12, 14)),
      ((12, 14), (8, 10)),
      ((8, 10), (4, 14)),
      ((4, 14), (4, 2)),
    ],
  );

  /// On hold: a pause.
  static const onHold = IconDef(
    fills: [
      [(4, 2), (7, 2), (7, 14), (4, 14)],
      [(9, 2), (12, 2), (12, 14), (9, 14)],
    ],
  );

  /// Dropped: a cross.
  static const dropped = IconDef(
    lines: [((3, 3), (13, 13)), ((13, 3), (3, 13))],
  );

  /// Not interested: a circle with a slash.
  static const notInterested = IconDef(
    lines: [
      ((5, 2), (11, 2)),
      ((11, 2), (14, 5)),
      ((14, 5), (14, 11)),
      ((14, 11), (11, 14)),
      ((11, 14), (5, 14)),
      ((5, 14), (2, 11)),
      ((2, 11), (2, 5)),
      ((2, 5), (5, 2)),
      ((5, 11), (11, 5)),
    ],
  );

  /// Rewatching: one arrow each way.
  static const rewatching = IconDef(
    lines: [
      ((3, 5), (12, 5)),
      ((10, 3), (12, 5)),
      ((10, 7), (12, 5)),
      ((13, 11), (4, 11)),
      ((6, 9), (4, 11)),
      ((6, 13), (4, 11)),
    ],
  );

  static const all = <String, IconDef>{
    'nekomimi': nekomimi,
    'discover': discover,
    'library': library,
    'watching': watching,
    'schedule': schedule,
    'settings': settings,
    'grid': grid,
    'list': list,
    'chevronDown': chevronDown,
    'check': check,
    'more': more,
    'planned': planned,
    'onHold': onHold,
    'dropped': dropped,
    'notInterested': notInterested,
    'rewatching': rewatching,
  };
}
