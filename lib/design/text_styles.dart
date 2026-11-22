import 'package:flutter/painting.dart';

import 'tokens.dart';

abstract final class AppText {
  // Chakra Petch has no kana or kanji; those fall back to Plex Sans JP.
  static const _labelFallback = [Tokens.sans];

  /// A plain label is Plex Sans JP; a bold one (buttons, tabs, titles) is
  /// Chakra Petch, its one weight.
  static TextStyle label(Color color, {bool bold = false}) => bold
      ? TextStyle(
          fontFamily: Tokens.label,
          fontFamilyFallback: _labelFallback,
          fontWeight: FontWeight.w600,
          fontSize: Tokens.text2,
          letterSpacing: Tokens.text2 * Tokens.labelTracking,
          height: 1,
          color: color,
        )
      : TextStyle(
          fontFamily: Tokens.sans,
          fontWeight: FontWeight.w400,
          fontSize: Tokens.text2,
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

  static const heading = TextStyle(
    fontFamily: Tokens.label,
    fontFamilyFallback: _labelFallback,
    fontWeight: FontWeight.w600,
    fontSize: Tokens.text3,
    letterSpacing: Tokens.text3 * Tokens.labelTracking,
    height: 1,
    color: Tokens.ink,
  );

  static TextStyle caption(Color color) => TextStyle(
    fontFamily: Tokens.sans,
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
}
