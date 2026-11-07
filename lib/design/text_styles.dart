import 'package:flutter/painting.dart';

import 'tokens.dart';

/// The text styles components share. Sizes and fonts come from the tokens.
abstract final class AppText {
  /// Labels on buttons and tabs.
  static TextStyle label(Color color) => TextStyle(
    fontFamily: Tokens.sans,
    fontSize: Tokens.text3,
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
