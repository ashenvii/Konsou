import 'icon_def.dart';

/// Every icon in the app. Add new ones here and to [all], so the angle test
/// checks them.
abstract final class AppIcons {
  /// The mascot's face. The fill is the head with both ears, the lines are the
  /// closed eyes and the nose. Draw the fill in mint and the lines in ground.
  static const nekomimi = IconDef(
    fills: [
      [(0, 0), (4, 4), (12, 4), (16, 0), (16, 16), (0, 16)],
    ],
    lines: [
      // Left eye, right eye.
      ((3, 10), (5, 8)),
      ((5, 8), (7, 10)),
      ((9, 10), (11, 8)),
      ((11, 8), (13, 10)),
      // Nose.
      ((7, 12), (9, 12)),
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
