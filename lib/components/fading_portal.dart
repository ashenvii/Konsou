import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'presence.dart';

/// An [OverlayPortal] whose overlay fades in and out with [Presence]. The
/// owner calls [controller]'s show when it sets [visible]; Flutter allows
/// that only outside build. Taking it down is done here, once the fade out
/// has finished, and not if it was asked for again in the meantime.
class FadingPortal extends StatefulWidget {
  const FadingPortal({
    super.key,
    required this.controller,
    required this.visible,
    required this.overlay,
    required this.child,
    this.slide = false,
    this.openTime = Tokens.motionOpen,
  });

  final OverlayPortalController controller;
  final bool visible;
  final WidgetBuilder overlay;
  final Widget child;
  final bool slide;
  final Duration openTime;

  @override
  State<FadingPortal> createState() => _FadingPortalState();
}

class _FadingPortalState extends State<FadingPortal> {
  void _gone() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = widget.controller;
      if (mounted && !widget.visible && controller.isShowing) {
        controller.hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: widget.controller,
      overlayChildBuilder: (context) => Presence(
        visible: widget.visible,
        slide: widget.slide,
        openTime: widget.openTime,
        onGone: _gone,
        child: widget.overlay(context),
      ),
      child: widget.child,
    );
  }
}

/// The open and closed state of a [FadingPortal] owned by a widget: [open]
/// shows it, running [also] in the same rebuild, and [close] lets it fade.
mixin FadingPortalOwner<T extends StatefulWidget> on State<T> {
  final portal = OverlayPortalController();
  var portalOpen = false;

  void openPortal([VoidCallback? also]) {
    setState(() {
      also?.call();
      portalOpen = true;
    });
    portal.show();
  }

  void closePortal() {
    if (portalOpen) setState(() => portalOpen = false);
  }
}
