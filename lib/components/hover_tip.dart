import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'countdown.dart';
import 'floating_panel.dart';
import 'popover_placement.dart';
import 'presence.dart';

/// Says in words what an icon does, beside it, after a short hover. It never
/// takes a click: the pointer goes straight through to what is underneath.
class HoverTip extends StatefulWidget {
  const HoverTip({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<HoverTip> createState() => _HoverTipState();
}

class _HoverTipState extends State<HoverTip> with HoverDelaysState<HoverTip> {
  final _controller = OverlayPortalController();
  Rect _anchor = Rect.zero;
  var _wanted = false;

  @override
  Duration get hoverOpenDelay => Tokens.tipDelay;

  RenderBox get _overlayBox =>
      Overlay.of(context).context.findRenderObject()! as RenderBox;

  @override
  void hoverOpen() {
    final box = context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: _overlayBox);
    setState(() {
      _anchor = topLeft & box.size;
      _wanted = true;
    });
    _controller.show();
  }

  // the fade out finishes first; Presence then calls _hide
  @override
  void hoverClose() => setState(() => _wanted = false);

  void _hide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_wanted && _controller.isShowing) _controller.hide();
    });
  }

  void _stop() {
    hoverDelays.left(isOpen: false);
    if (_wanted) setState(() => _wanted = false);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: Presence(
              visible: _wanted,
              openTime: Tokens.motionTip,
              onGone: _hide,
              child: CustomSingleChildLayout(
                delegate: AnchoredLayout(_anchor, Tokens.space1, placeBeside),
                child: FloatingPanel(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.space3,
                      vertical: Tokens.space2,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      style: AppText.label(Tokens.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => hoverDelays.entered(isOpen: _wanted),
        onExit: (_) => hoverDelays.left(isOpen: _wanted),
        child: Listener(onPointerDown: (_) => _stop(), child: widget.child),
      ),
    );
  }
}
