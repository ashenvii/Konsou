import 'package:flutter/painting.dart';

/// Every color, size, radius and font in the app is defined here and nowhere
/// else. Values match notes/design/tokens.md. Add one only when the owner says so.
abstract final class Tokens {
  // Colors
  static const Color ground = Color(0xFF080D10);
  static const Color ink = Color(0xFFF4F5F5);
  static const Color inkSoft = Color(0xFFBCC1C4);
  static const Color inkMuted = Color(0xFF6E838C);
  static const Color amber = Color(0xFFF2B33D);
  static const Color mint = Color(0xFF3DD6A0);
  static const Color red = Color(0xFFE5484D);
  // Fill of secondary buttons, fields and panels (approved 2026-11-08).
  static const Color surface = Color(0xFF0F1F25);

  // Radius: square everywhere
  static const BorderRadius square = BorderRadius.zero;

  // Space
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;

  // Type sizes
  static const double text1 = 11;
  static const double text2 = 12;
  static const double text3 = 14;
  static const double text4 = 18;
  static const double text5 = 26;

  // Fonts
  static const String sans = 'PlexSans';
  static const String mono = 'PlexMono';

  // Shell sizes, measured from the comp and approved 2026-11-08.
  // windowIconSize is not measured yet.
  static const double barHeight = 36;
  static const double railWidth = 48;
  static const double railItemSize = 36;
  static const double windowButtonWidth = 40;
  static const double windowIconSize = 10;

  // Component sizes, measured from the comp and approved 2026-11-08.
  // focusRing is not in the comp.
  static const double controlHeight = 36;
  static const double badgeSize = 16;
  static const double checkboxSize = 20;
  static const double checkboxBorder = 2;
  static const double focusRing = 2;
  // Smallest area a finger can hit, on touch screens (Android guideline).
  static const double touchTarget = 48;
}
