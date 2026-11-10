import 'package:flutter/painting.dart';

import 'tokens.dart';

/// The text styles components share. Sizes and fonts come from the tokens.
abstract final class AppText {
  /// Labels on buttons and tabs. [bold] is for the selected tab and the amber
  /// button, so a dark label on a light fill does not read thin.
  static TextStyle label(Color color, {bool bold = false}) => TextStyle(
    fontFamily: Tokens.sans,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    fontSize: Tokens.text3,
    height: 1,
    color: color,
  );

  /// A page's name at the top left.
  static const heading = TextStyle(
    fontFamily: Tokens.sans,
    fontWeight: FontWeight.w700,
    fontSize: Tokens.text5,
    height: 1,
    color: Tokens.ink,
  );

  /// The small line under a title.
  static TextStyle caption(Color color) => TextStyle(
    fontFamily: Tokens.sans,
    fontSize: Tokens.text2,
    height: 1,
    color: color,
  );

  /// Counts and scores beside a row: small, mono.
  static TextStyle figure(Color color) => TextStyle(
    fontFamily: Tokens.mono,
    fontSize: Tokens.text2,
    height: 1,
    color: color,
  );

  /// Numbers inside a count badge.
  static TextStyle count(Color color) => TextStyle(
    fontFamily: Tokens.mono,
    fontWeight: FontWeight.w700,
    fontSize: Tokens.text1,
    height: 1,
    color: color,
  );
}
