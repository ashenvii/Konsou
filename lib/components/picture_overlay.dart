import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'close_on_escape.dart';
import 'page_dim.dart';

/// A picture shown large over the dimmed page. [builder] gets the room left
/// inside the page's margin. A click anywhere outside a control, or Escape,
/// closes it; [onKey] sees the other keys first.
class PictureOverlay extends StatelessWidget {
  const PictureOverlay({
    super.key,
    required this.onClose,
    required this.builder,
    this.onKey,
  });

  final VoidCallback onClose;
  final Widget Function(BuildContext context, BoxConstraints room) builder;
  final KeyEventResult Function(KeyEvent event)? onKey;

  @override
  Widget build(BuildContext context) {
    final onKey = this.onKey;
    return CloseOnEscape(
      onClose: onClose,
      child: Focus(
        autofocus: true,
        onKeyEvent: onKey == null ? null : (node, event) => onKey(event),
        child: PageDim(
          onClose: onClose,
          child: LayoutBuilder(
            builder: (context, constraints) => builder(
              context,
              constraints.deflate(const EdgeInsets.all(Tokens.space5)),
            ),
          ),
        ),
      ),
    );
  }
}
