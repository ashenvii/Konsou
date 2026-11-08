import 'dart:io';

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// On a touch screen, makes whatever is inside at least [Tokens.touchTarget]
/// square to hit, without making it look bigger: the child stays centered at
/// its own size. On desktop it does nothing.
class TouchTarget extends StatelessWidget {
  const TouchTarget({super.key, required this.child});

  final Widget child;

  /// Tests set this to try the touch layout on a desktop machine.
  @visibleForTesting
  static bool? debugForce;

  static bool get active =>
      debugForce ?? (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: Tokens.touchTarget,
        minHeight: Tokens.touchTarget,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}
