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

  static const arrowLeft = IconDef(
    lines: [((3, 8), (13, 8)), ((7, 4), (3, 8)), ((3, 8), (7, 12))],
  );

  static const chevronLeft = IconDef(
    lines: [((10, 3), (5, 8)), ((5, 8), (10, 13))],
  );

  static const chevronRight = IconDef(
    lines: [((6, 3), (11, 8)), ((11, 8), (6, 13))],
  );

  static const pencil = IconDef(
    lines: [
      ((2, 14), (2, 11)),
      ((2, 11), (10, 3)),
      ((10, 3), (13, 6)),
      ((13, 6), (5, 14)),
      ((5, 14), (2, 14)),
      ((2, 11), (5, 14)),
      ((8, 5), (11, 8)),
    ],
  );

  // the facts on the Detail page
  static const rank = IconDef(
    lines: [
      ((2, 14), (2, 9)),
      ((2, 9), (6, 9)),
      ((6, 9), (6, 5)),
      ((6, 5), (10, 5)),
      ((10, 5), (10, 8)),
      ((10, 8), (14, 8)),
      ((14, 8), (14, 14)),
      ((14, 14), (2, 14)),
    ],
  );

  static const done = IconDef(
    lines: [
      ((2, 2), (14, 2)),
      ((14, 2), (14, 14)),
      ((14, 14), (2, 14)),
      ((2, 14), (2, 2)),
      ((5, 8), (7, 10)),
      ((7, 10), (11, 6)),
    ],
  );

  static const play = IconDef(
    lines: [((5, 3), (10, 8)), ((10, 8), (5, 13)), ((5, 13), (5, 3))],
  );

  static const plus = IconDef(lines: [((3, 8), (13, 8)), ((8, 3), (8, 13))]);

  static const minus = IconDef(lines: [((3, 8), (13, 8))]);

  // two people, one behind the other
  static const people = IconDef(
    lines: [
      ((4, 3), (8, 3)),
      ((8, 3), (8, 7)),
      ((8, 7), (4, 7)),
      ((4, 7), (4, 3)),
      ((2, 14), (2, 11)),
      ((2, 11), (4, 9)),
      ((4, 9), (8, 9)),
      ((8, 9), (10, 11)),
      ((10, 11), (10, 14)),
      ((10, 3), (13, 3)),
      ((13, 3), (13, 7)),
      ((13, 7), (10, 7)),
      ((11, 9), (12, 9)),
      ((12, 9), (14, 11)),
      ((14, 11), (14, 14)),
    ],
  );

  // opens outside the app, in the browser
  static const external = IconDef(
    lines: [
      ((7, 3), (3, 3)),
      ((3, 3), (3, 13)),
      ((3, 13), (13, 13)),
      ((13, 13), (13, 9)),
      ((8, 8), (14, 2)),
      ((10, 2), (14, 2)),
      ((14, 2), (14, 6)),
    ],
  );

  // open full size
  static const expand = IconDef(
    lines: [
      ((2, 6), (2, 2)),
      ((2, 2), (6, 2)),
      ((10, 2), (14, 2)),
      ((14, 2), (14, 6)),
      ((14, 10), (14, 14)),
      ((14, 14), (10, 14)),
      ((6, 14), (2, 14)),
      ((2, 14), (2, 10)),
    ],
  );

  // the window buttons
  static const minimize = IconDef(lines: [((3, 12), (13, 12))]);

  static const maximize = IconDef(
    lines: [
      ((3, 3), (13, 3)),
      ((13, 3), (13, 13)),
      ((13, 13), (3, 13)),
      ((3, 13), (3, 3)),
    ],
  );

  // a window that can shrink back: the square with another behind it
  static const restore = IconDef(
    lines: [
      ((2, 6), (10, 6)),
      ((10, 6), (10, 14)),
      ((10, 14), (2, 14)),
      ((2, 14), (2, 6)),
      ((6, 6), (6, 2)),
      ((6, 2), (14, 2)),
      ((14, 2), (14, 10)),
      ((14, 10), (10, 10)),
    ],
  );

  static const close = IconDef(lines: [((3, 3), (13, 13)), ((13, 3), (3, 13))]);

  static const bin = IconDef(
    lines: [
      // lid, handle, body, two slots
      ((2, 4), (14, 4)),
      ((6, 4), (6, 2)),
      ((6, 2), (10, 2)),
      ((10, 2), (10, 4)),
      ((4, 6), (4, 14)),
      ((4, 14), (12, 14)),
      ((12, 14), (12, 6)),
      ((6, 8), (6, 12)),
      ((10, 8), (10, 12)),
    ],
  );

  static const all = <String, IconDef>{
    'nekomimi': nekomimi,
    'bell': bell,
    'bin': bin,
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
    'arrowLeft': arrowLeft,
    'pencil': pencil,
    'rank': rank,
    'done': done,
    'play': play,
    'chevronLeft': chevronLeft,
    'chevronRight': chevronRight,
    'plus': plus,
    'minus': minus,
    'people': people,
    'external': external,
    'expand': expand,
    'minimize': minimize,
    'maximize': maximize,
    'restore': restore,
    'close': close,
  };
}
