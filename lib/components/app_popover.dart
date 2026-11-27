import 'package:flutter/widgets.dart';

import 'close_on_escape.dart';
import 'popover_placement.dart';
import 'fading_portal.dart';
import 'presence.dart';

abstract interface class PopoverHandle {
  bool get isOpen;

  void open();

  void openAt(Offset globalPosition);

  /// Opens against [anchor], a rect in window coordinates. [lift] is a rect
  /// the backdrop is told about, such as the card the popover belongs to.
  void openOver(Rect anchor, {Rect? lift});
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
    this.place = placePopover,
    this.backdrop,
  });

  final PopoverBuilder builder;
  final PopoverBuilder popoverBuilder;

  final double gap;

  /// Where the popover goes against its anchor.
  final Placer place;

  /// Drawn between the page and the popover, given the lift rect (the anchor
  /// when none was given) in the popover layer's coordinates. It takes the
  /// clicks that would otherwise close the popover.
  final Widget Function(BuildContext context, PopoverHandle handle, Rect lift)?
  backdrop;

  final ValueChanged<bool>? onAnchorHover;

  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends State<AppPopover>
    with FadingPortalOwner<AppPopover>
    implements PopoverHandle {
  Rect _anchor = Rect.zero;
  Rect _lift = Rect.zero;

  @override
  bool get isOpen => portalOpen;

  @override
  void open() => _show(measureAnchor());

  @override
  void openAt(Offset globalPosition) =>
      _show(overlayBox.globalToLocal(globalPosition) & Size.zero);

  @override
  void openOver(Rect anchor, {Rect? lift}) =>
      _show(_toLayer(anchor), lift: lift == null ? null : _toLayer(lift));

  Rect _toLayer(Rect global) =>
      overlayBox.globalToLocal(global.topLeft) & global.size;

  void _show(Rect anchor, {Rect? lift}) => openPortal(() {
    _anchor = anchor;
    _lift = lift ?? anchor;
  });

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
        place: widget.place,
        backdrop: widget.backdrop?.call(context, this, _lift),
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
    required this.place,
    required this.backdrop,
    required this.onAnchorHover,
    required this.onClose,
    required this.child,
  });

  final Rect anchor;
  final double gap;
  final Placer place;
  final Widget? backdrop;
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
              child:
                  backdrop ??
                  GestureDetector(
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
                  place,
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
