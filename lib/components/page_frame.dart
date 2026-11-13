import 'dart:io';

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The space around a page's top row. The top matches the rail's, so the row
/// starts level with the rail's first icon. Content below the row keeps the
/// same sides; a scroll view takes them as its own padding, so its scrollbar
/// can sit against the window's edge.
abstract final class PageFrame {
  static const top = EdgeInsets.fromLTRB(
    Tokens.space5,
    Tokens.space2,
    Tokens.space5,
    Tokens.space4,
  );

  /// The rail's width where there is one. A page centres a control on the
  /// window, not on the page, so it leaves this much empty on its right.
  static double get railInset => Platform.isWindows ? Tokens.railWidth : 0;

  static const content = EdgeInsets.fromLTRB(
    Tokens.space5,
    0,
    Tokens.space5,
    Tokens.space5,
  );
}
