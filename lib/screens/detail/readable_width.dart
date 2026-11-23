import 'package:flutter/widgets.dart';

import '../../design/tokens.dart';

/// Keeps a column of text to a width that reads comfortably, at the left.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Tokens.detailTextWidth),
      child: child,
    ),
  );
}
