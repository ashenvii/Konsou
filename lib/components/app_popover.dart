import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'popover_placement.dart';

/// What a popover's anchor can do: open under itself or at a pointer, close.
abstract interface class PopoverHandle {
  bool get isOpen;

  /// Opens under the anchor.
  void open();

  /// Opens with its corner at a pointer position in window coordinates, for a
  /// right click menu.
  void openAt(Offset globalPosition);
  void close();
}

/// Something that opens on top of the page: a click outside or Escape closes
/// it, and it stays on screen. [builder] draws the anchor, [popoverBuilder]
/// draws what opens. It needs an Overlay above it that fills the window, which
/// the app's router gives it.
class AppPopover extends StatefulWidget {
  const AppPopover({
    super.key,
    required this.builder,
    required this.popoverBuilder,
  });

  final Widget Function(BuildContext context, PopoverHandle handle) builder;
  final Widget Function(BuildContext context, PopoverHandle handle)
  popoverBuilder;

  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends State<AppPopover> implements PopoverHandle {
  final _controller = OverlayPortalController();
  Rect _anchor = Rect.zero;
  var _open = false;

  @override
  bool get isOpen => _open;

  @override
  void open() {
    final box = context.findRenderObject()! as RenderBox;
    _show(box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  void openAt(Offset globalPosition) => _show(globalPosition & Size.zero);

  void _show(Rect anchor) {
    setState(() {
      _anchor = anchor;
      _open = true;
    });
    _controller.show();
  }

  @override
  void close() {
    if (!_open) return;
    setState(() => _open = false);
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (context) => _PopoverLayer(
        anchor: _anchor,
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
    required this.onClose,
    required this.child,
  });

  final Rect anchor;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              onClose();
              return null;
            },
          ),
        },
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
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: _PopoverLayout(anchor),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      placePopover(anchor: anchor, child: childSize, area: size);

  @override
  bool shouldRelayout(_PopoverLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}
