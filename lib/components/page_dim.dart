import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The dim laid over a page under something that asks for all the attention,
/// Quick search and the Library's quick panel. A click on it, a right click,
/// or with [closeOnWheel] a turn of the wheel or a touchpad scroll calls
/// [onClose].
class PageDim extends StatelessWidget {
  const PageDim({super.key, required this.onClose, this.closeOnWheel = false});

  final VoidCallback onClose;
  final bool closeOnWheel;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: closeOnWheel
          ? (event) {
              if (event is PointerScrollEvent) onClose();
            }
          : null,
      // a touchpad's two finger scroll is a pan, not a wheel signal
      onPointerPanZoomStart: closeOnWheel ? (_) => onClose() : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        onSecondaryTap: onClose,
        child: ColoredBox(
          color: Tokens.wellEdge.withValues(alpha: Tokens.dimAlpha),
        ),
      ),
    );
  }
}
