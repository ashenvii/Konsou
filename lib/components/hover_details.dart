import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'fading_portal.dart';
import 'details_panel.dart';
import 'hover_delays_state.dart';
import 'popover_placement.dart';

/// A panel of [details] beside [child], opened after [Tokens.tipDelay] while
/// the pointer rests on it or while it has keyboard focus ([focused]). It
/// stays while the pointer is on either, so the panel can be used, and closes
/// once both the pointer and the focus have left. A press on [child] closes
/// it, so a click or a menu is never covered. Nothing on a touch screen.
class HoverDetails extends StatefulWidget {
  const HoverDetails({
    super.key,
    required this.focused,
    required this.details,
    required this.child,
    this.enabled = true,
  });

  final bool focused;
  final WidgetBuilder details;
  final Widget child;
  final bool enabled;

  @override
  State<HoverDetails> createState() => _HoverDetailsState();
}

class _HoverDetailsState extends State<HoverDetails>
    with HoverDelaysState<HoverDetails>, FadingPortalOwner<HoverDetails> {
  Rect _anchor = Rect.zero;
  var _overChild = false;
  var _overPanel = false;

  bool get _wanted =>
      widget.enabled && (_overChild || _overPanel || widget.focused);

  @override
  Duration get hoverOpenDelay => Tokens.tipDelay;

  @override
  void hoverOpen() {
    if (!_wanted) return;
    final anchor = measureAnchor();
    openPortal(() => _anchor = anchor);
  }

  @override
  void hoverClose() {
    if (!_wanted) closePortal();
  }

  void _changed() => _wanted
      ? hoverDelays.entered(isOpen: portalOpen)
      : hoverDelays.left(isOpen: portalOpen);

  @override
  void initState() {
    super.initState();
    if (_wanted) _changed();
  }

  @override
  void didUpdateWidget(HoverDetails old) {
    super.didUpdateWidget(old);
    if (old.focused != widget.focused || old.enabled != widget.enabled) {
      _changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadingPortal(
      controller: portal,
      visible: portalOpen,
      overlay: (context) => CustomSingleChildLayout(
        delegate: AnchoredLayout(_anchor, Tokens.space2, placeBeside),
        child: MouseRegion(
          onEnter: (_) {
            _overPanel = true;
            _changed();
          },
          onExit: (_) {
            _overPanel = false;
            _changed();
          },
          child: DetailsPanel(child: widget.details(context)),
        ),
      ),
      child: MouseRegion(
        onEnter: (_) {
          _overChild = true;
          _changed();
        },
        onExit: (_) {
          _overChild = false;
          _changed();
        },
        child: Listener(onPointerDown: (_) => _pressed(), child: widget.child),
      ),
    );
  }

  void _pressed() {
    _overChild = false;
    hoverDelays.left(isOpen: false);
    closePortal();
  }
}
