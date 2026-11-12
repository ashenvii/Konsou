import 'package:flutter/painting.dart';

import 'tokens.dart';

abstract final class AppText {
  static TextStyle label(Color color, {bool bold = false}) => TextStyle(
    fontFamily: Tokens.sans,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    fontSize: Tokens.text3,
    height: 1,
    color: color,
  );

  static const heading = TextStyle(
    fontFamily: Tokens.sans,
    fontWeight: FontWeight.w700,
    fontSize: Tokens.text4,
    height: 1,
    color: Tokens.ink,
  );

  static const subheading = TextStyle(
    fontFamily: Tokens.sans,
    fontWeight: FontWeight.w700,
    fontSize: Tokens.text4,
    height: 1,
    color: Tokens.ink,
  );

  static TextStyle caption(Color color) => TextStyle(
    fontFamily: Tokens.sans,
    fontSize: Tokens.text2,
    height: 1,
    color: color,
  );

  static TextStyle figure(Color color) => TextStyle(
    fontFamily: Tokens.mono,
    fontSize: Tokens.text2,
    height: 1,
    color: color,
  );

  static TextStyle count(Color color) => TextStyle(
    fontFamily: Tokens.mono,
    fontWeight: FontWeight.w700,
    fontSize: Tokens.text1,
    height: 1,
    color: color,
  );

  static TextStyle tally(Color color, {double size = Tokens.text3}) =>
      TextStyle(
        fontFamily: Tokens.sans,
        fontSize: size,
        height: 1,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
