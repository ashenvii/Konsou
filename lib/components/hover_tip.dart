import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'hover_delays_state.dart';
import 'floating_panel.dart';
import 'popover_placement.dart';
import 'fading_portal.dart';

/// Says in words what an icon does, beside it, after a short hover. It never
/// takes a click: the pointer goes straight through to what is underneath.
/// Each time [reveal] fires it shows at once, without the wait.
class HoverTip extends StatefulWidget {
  const HoverTip({
    super.key,
    required this.label,
    required this.child,
    this.reveal,
  });

  final String label;
  final Widget child;
  final Listenable? reveal;

  @override
  State<HoverTip> createState() => _HoverTipState();
}

class _HoverTipState extends State<HoverTip>
    with HoverDelaysState<HoverTip>, FadingPortalOwner<HoverTip> {
  Rect _anchor = Rect.zero;

  @override
  Duration get hoverOpenDelay => Tokens.tipDelay;

  @override
  void hoverOpen() {
    final anchor = measureAnchor();
    openPortal(() => _anchor = anchor);
  }

  @override
  void hoverClose() => closePortal();

  @override
  void initState() {
    super.initState();
    widget.reveal?.addListener(hoverOpen);
  }

  @override
  void didUpdateWidget(HoverTip old) {
    super.didUpdateWidget(old);
    if (old.reveal != widget.reveal) {
      old.reveal?.removeListener(hoverOpen);
      widget.reveal?.addListener(hoverOpen);
    }
  }

  @override
  void dispose() {
    widget.reveal?.removeListener(hoverOpen);
    super.dispose();
  }

  void _stop() {
    hoverDelays.left(isOpen: false);
    closePortal();
  }

  @override
  Widget build(BuildContext context) {
    return FadingPortal(
      controller: portal,
      visible: portalOpen,
      openTime: Tokens.motionTip,
      overlay: (context) => IgnorePointer(
        child: ExcludeSemantics(
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
      child: MouseRegion(
        onEnter: (_) => hoverDelays.entered(isOpen: portalOpen),
        onExit: (_) => hoverDelays.left(isOpen: portalOpen),
        child: Listener(onPointerDown: (_) => _stop(), child: widget.child),
      ),
    );
  }
}
