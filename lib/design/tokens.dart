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

  // Shell sizes (proposed 2026-11-08, waiting for the owner's approval)
  static const double barHeight = 40;
  static const double railWidth = 56;
  static const double windowButtonWidth = 46;
  static const double windowIconSize = 10;
}
