import 'icon_def.dart';

abstract final class AppIcons {
  static const nekomimi = IconDef(
    columns: 40,
    rows: 42,
    lineWidth: 3.5,
    thinWidth: 2,
    mascot: true,
    fills: [
      // ear tip, outer edge, bottom, other side, with a flat notch between
      [(0, 0), (13, 13), (27, 13), (40, 0), (40, 42), (0, 42)],
    ],
    shades: [
      // the small triangle inside each ear, in its lower inner corner.
      [(2, 8), (2, 13), (7, 13)],
      [(38, 8), (38, 13), (33, 13)],
    ],
    lines: [
      // left eye, right eye.
      ((9, 25), (12, 22)),
      ((12, 22), (15, 25)),
      ((25, 25), (28, 22)),
      ((28, 22), (31, 25)),
    ],
    thinLines: [
      // mouth: a small w, with a raised middle peak.
      ((17, 33), (18, 34)),
      ((18, 34), (20, 32)),
      ((20, 32), (22, 34)),
      ((22, 34), (23, 33)),
    ],
  );

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

  static const library = IconDef(
    lines: [
      ((1, 3), (6, 3)),
      ((6, 3), (8, 5)),
      ((8, 5), (10, 3)),
      ((10, 3), (15, 3)),
      ((15, 3), (15, 12)),
      ((15, 12), (10, 12)),
      ((10, 12), (8, 14)),
      ((8, 14), (6, 12)),
      ((6, 12), (1, 12)),
      ((1, 12), (1, 3)),
      ((8, 5), (8, 14)),
    ],
  );

  static const watching = IconDef(
    lines: [((6, 2), (12, 8)), ((12, 8), (6, 14)), ((6, 14), (6, 2))],
  );

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

  static const settings = IconDef(
    fills: [
      [(9, 2), (11, 2), (11, 4), (9, 4)],
      [(4, 7), (6, 7), (6, 9), (4, 9)],
      [(10, 12), (12, 12), (12, 14), (10, 14)],
    ],
    lines: [((2, 3), (14, 3)), ((2, 8), (14, 8)), ((2, 13), (14, 13))],
  );

  static const grid = IconDef(
    fills: [
      [(2, 2), (7, 2), (7, 7), (2, 7)],
      [(9, 2), (14, 2), (14, 7), (9, 7)],
      [(2, 9), (7, 9), (7, 14), (2, 14)],
      [(9, 9), (14, 9), (14, 14), (9, 14)],
    ],
  );

  static const list = IconDef(
    fills: [
      [(2, 2), (4, 2), (4, 4), (2, 4)],
      [(2, 7), (4, 7), (4, 9), (2, 9)],
      [(2, 12), (4, 12), (4, 14), (2, 14)],
    ],
    lines: [((6, 3), (14, 3)), ((6, 8), (14, 8)), ((6, 13), (14, 13))],
  );

  static const chevronDown = IconDef(
    lines: [((3, 6), (8, 11)), ((8, 11), (13, 6))],
  );

  static const check = IconDef(lines: [((3, 8), (6, 11)), ((6, 11), (13, 4))]);

  static const menu = IconDef(
    lines: [((2, 4), (14, 4)), ((2, 8), (14, 8)), ((2, 12), (14, 12))],
  );

  static const more = IconDef(
    fills: [
      [(7, 2), (9, 2), (9, 4), (7, 4)],
      [(7, 7), (9, 7), (9, 9), (7, 9)],
      [(7, 12), (9, 12), (9, 14), (7, 14)],
    ],
  );

  static const planned = IconDef(
    lines: [
      ((4, 2), (12, 2)),
      ((12, 2), (12, 14)),
      ((12, 14), (8, 10)),
      ((8, 10), (4, 14)),
      ((4, 14), (4, 2)),
    ],
  );

  static const onHold = IconDef(
    fills: [
      [(4, 2), (7, 2), (7, 14), (4, 14)],
      [(9, 2), (12, 2), (12, 14), (9, 14)],
    ],
  );

  static const dropped = IconDef(
    lines: [((3, 3), (13, 13)), ((13, 3), (3, 13))],
  );

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

  static const rewatching = IconDef(
    lines: [
      ((3, 5), (12, 5)),
      ((10, 3), (12, 5)),
      ((12, 5), (10, 7)),
      ((13, 11), (4, 11)),
      ((6, 9), (4, 11)),
      ((4, 11), (6, 13)),
    ],
  );

  static const search = IconDef(
    lines: [
      ((2, 2), (10, 2)),
      ((10, 2), (10, 10)),
      ((10, 10), (2, 10)),
      ((2, 10), (2, 2)),
      ((10, 10), (14, 14)),
    ],
  );

  static const bell = IconDef(
    lines: [
      ((8, 1), (8, 3)),
      ((6, 3), (10, 3)),
      ((10, 3), (12, 5)),
      ((12, 5), (12, 9)),
      ((12, 9), (14, 11)),
      ((14, 11), (14, 12)),
      ((14, 12), (2, 12)),
      ((2, 12), (2, 11)),
      ((2, 11), (4, 9)),
      ((4, 9), (4, 5)),
      ((4, 5), (6, 3)),
      ((6, 14), (10, 14)),
    ],
  );

  static const heart = IconDef(
    lines: [
      ((8, 5), (6, 3)),
      ((6, 3), (4, 3)),
      ((4, 3), (2, 5)),
      ((2, 5), (2, 7)),
      ((2, 7), (8, 13)),
      ((8, 13), (14, 7)),
      ((14, 7), (14, 5)),
      ((14, 5), (12, 3)),
      ((12, 3), (10, 3)),
      ((10, 3), (8, 5)),
    ],
  );

  static const all = <String, IconDef>{
    'nekomimi': nekomimi,
    'bell': bell,
    'heart': heart,
    'discover': discover,
    'library': library,
    'watching': watching,
    'schedule': schedule,
    'settings': settings,
    'grid': grid,
    'list': list,
    'chevronDown': chevronDown,
    'check': check,
    'menu': menu,
    'more': more,
    'planned': planned,
    'onHold': onHold,
    'dropped': dropped,
    'notInterested': notInterested,
    'rewatching': rewatching,
    'search': search,
  };
}
