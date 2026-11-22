import 'package:flutter/widgets.dart';

import 'close_on_escape.dart';
import 'popover_placement.dart';
import 'fading_portal.dart';
import 'presence.dart';

abstract interface class PopoverHandle {
  bool get isOpen;

  void open();

  void openAt(Offset globalPosition);
  void close();
}

typedef PopoverBuilder = Widget Function(
  BuildContext context,
  PopoverHandle handle,
);

class AppPopover extends StatefulWidget {
  const AppPopover({
    super.key,
    required this.builder,
    required this.popoverBuilder,
    this.gap = 0,
    this.onAnchorHover,
  });

  final PopoverBuilder builder;
  final PopoverBuilder popoverBuilder;

  final double gap;

  final ValueChanged<bool>? onAnchorHover;

  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends State<AppPopover>
    with FadingPortalOwner<AppPopover>
    implements PopoverHandle {
  Rect _anchor = Rect.zero;

  @override
  bool get isOpen => portalOpen;

  // the page's overlay starts below the bar and right of the rail
  RenderBox get _overlayBox =>
      Overlay.of(context).context.findRenderObject()! as RenderBox;

  @override
  void open() {
    final box = context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: _overlayBox);
    _show(topLeft & box.size);
  }

  @override
  void openAt(Offset globalPosition) =>
      _show(_overlayBox.globalToLocal(globalPosition) & Size.zero);

  void _show(Rect anchor) => openPortal(() => _anchor = anchor);

  @override
  void close() => closePortal();

  @override
  Widget build(BuildContext context) {
    return FadingPortal(
      controller: portal,
      visible: portalOpen,
      overlay: (context) => _PopoverLayer(
        anchor: _anchor,
        gap: widget.gap,
        onAnchorHover: widget.onAnchorHover,
        onClose: close,
        child: widget.popoverBuilder(context, this),
      ),
      child: widget.builder(context, this),
    );
  }
}

class _PopoverLayer extends StatelessWidget {
  const _PopoverLayer({
    required this.anchor,
    required this.gap,
    required this.onAnchorHover,
    required this.onClose,
    required this.child,
  });

  final Rect anchor;
  final double gap;
  final ValueChanged<bool>? onAnchorHover;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CloseOnEscape(
      onClose: onClose,
      child: FocusScope(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                onSecondaryTap: onClose,
              ),
            ),
            if (onAnchorHover != null)
              Positioned.fromRect(
                rect: anchor,
                child: MouseRegion(
                  opaque: true,
                  onEnter: (_) => onAnchorHover!(true),
                  onExit: (_) => onAnchorHover!(false),
                  child: GestureDetector(behavior: HitTestBehavior.opaque),
                ),
              ),
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: AnchoredLayout(
                  anchor,
                  gap,
                  placePopover,
                  shown: Presence.shownOf(context),
                ),
                // moved each frame of the slide, never redrawn
                child: RepaintBoundary(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
