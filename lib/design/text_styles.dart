import 'package:flutter/painting.dart';

import 'tokens.dart';

/// The text styles, built from the tokens.
abstract final class AppText {
  /// How far a style's capitals sit above the middle of their line box, as a
  /// share of the font size. Measured from rendered capitals at 16 px:
  /// Plex Sans JP 3 px, Chakra Petch 2 px, Share Tech Mono half a pixel.
  static const _capRise = {Tokens.sans: 0.1875, Tokens.label: 0.125};
  static const _capRiseMono = 0.04;

  /// The whole pixels to move text down so its capitals centre on their box,
  /// for the eye. The line box is centred already, but the capitals are not.
  static double capDrop(TextStyle style) {
    final share = _capRise[style.fontFamily] ?? _capRiseMono;
    return (share * (style.fontSize ?? Tokens.text2)).roundToDouble();
  }

  // Chakra Petch has no kana or kanji; those fall back to Plex Sans JP.
  static const _labelFallback = [Tokens.sans];

  /// A plain label is Plex Sans JP; a bold one (buttons, tabs, titles) is
  /// Chakra Petch, its one weight, tracked by its [size].
  static TextStyle label(
    Color color, {
    bool bold = false,
    double size = Tokens.text2,
  }) => bold
      ? TextStyle(
          fontFamily: Tokens.label,
          fontFamilyFallback: _labelFallback,
          fontWeight: FontWeight.w600,
          fontSize: size,
          letterSpacing: size * Tokens.labelTracking,
          height: 1,
          color: color,
        )
      : TextStyle(
          fontFamily: Tokens.sans,
          fontWeight: FontWeight.w400,
          fontSize: size,
          height: 1,
          color: color,
        );

  /// Like [label] but for text that may wrap onto more lines.
  static TextStyle paragraph(Color color) => TextStyle(
    fontFamily: Tokens.sans,
    fontSize: Tokens.text2,
    height: Tokens.lineHeightWrapped,
    color: color,
  );

  /// A page or section title: a bold [label] one size up.
  static final heading = label(Tokens.ink, bold: true, size: Tokens.text3);

  /// Small text under or beside a label. A bold one is Plex Sans JP Bold.
  static TextStyle caption(Color color, {bool bold = false}) => TextStyle(
    fontFamily: Tokens.sans,
    fontWeight: bold ? FontWeight.w700 : null,
    fontSize: Tokens.text1,
    height: 1,
    color: color,
  );

  /// Every number. Share Tech Mono has one weight, so a count stands out by
  /// its colour, not by bold.
  static TextStyle tally(Color color, {double size = Tokens.text2}) =>
      TextStyle(
        fontFamily: Tokens.mono,
        fontSize: size,
        height: 1,
        color: color,
      );

  /// LED digits: a [tally] glowing in its own colour.
  static TextStyle led(Color color, {double size = Tokens.text2}) =>
      tally(color, size: size).copyWith(
        shadows: [Shadow(color: color, blurRadius: Tokens.ledGlow)],
      );
}

/// Any style on the taller line height, for text that may wrap onto more
/// lines.
extension WrappedText on TextStyle {
  TextStyle get wrapped => copyWith(height: Tokens.lineHeightWrapped);
}
