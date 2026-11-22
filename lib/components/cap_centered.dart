import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';

/// Moves text down by [AppText.capDrop] so its capitals sit at the middle of
/// the box around it. Layout does not change; only the painting moves.
class CapCentered extends StatelessWidget {
  const CapCentered({super.key, required this.style, required this.child});

  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(0, AppText.capDrop(style)),
    child: child,
  );
}
