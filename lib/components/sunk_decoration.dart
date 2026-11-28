import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The faint lit lip under anything sunk into the console: a well, a display.
const wellLip = BoxShadow(color: Tokens.edgeLight, offset: Offset(0, 1));

/// A small display sunk into the console, the box counts and episode steps
/// sit in.
const sunkDisplay = BoxDecoration(
  color: Tokens.wellFill,
  borderRadius: Tokens.coverCorners,
  boxShadow: [wellLip],
);
