import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A gallery block on the surface color.
class GalleryPanel extends StatelessWidget {
  const GalleryPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Tokens.surface,
    child: Padding(padding: const EdgeInsets.all(Tokens.space4), child: child),
  );
}
