import 'package:flutter/widgets.dart';

import 'app_popover.dart';
import 'countdown.dart';

class HoverPopover extends StatefulWidget {
  const HoverPopover({
    super.key,
    required this.builder,
    required this.popoverBuilder,
    this.gap = 0,
  });

  final PopoverBuilder builder;
  final PopoverBuilder popoverBuilder;

  final double gap;

  @override
  State<HoverPopover> createState() => _HoverPopoverState();
}

enum _Spot { anchor, anchorCover, popover }

class _HoverPopoverState extends State<HoverPopover>
    with HoverDelaysState<HoverPopover> {
  // enter and exit arrive in no fixed order, so decide from the whole set
  final _over = <_Spot>{};
  PopoverHandle? _handle;

  bool get _isOpen => _handle?.isOpen ?? false;

  void _moved(_Spot spot, {required bool inside}) {
    // a popover closed by a click never sends its exit
    if (!_isOpen) _over.removeWhere((s) => s != _Spot.anchor);
    inside ? _over.add(spot) : _over.remove(spot);
    _over.isEmpty
        ? hoverDelays.left(isOpen: _isOpen)
        : hoverDelays.entered(isOpen: _isOpen);
  }

  @override
  void hoverOpen() {
    if (_over.isNotEmpty) _handle?.open();
  }

  @override
  void hoverClose() {
    if (_over.isEmpty) _handle?.close();
  }

  Widget _watch(_Spot spot, Widget child) => MouseRegion(
    onEnter: (_) => _moved(spot, inside: true),
    onExit: (_) => _moved(spot, inside: false),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return AppPopover(
      gap: widget.gap,
      onAnchorHover: (inside) => _moved(_Spot.anchorCover, inside: inside),
      builder: (context, handle) {
        _handle = handle;
        return _watch(_Spot.anchor, widget.builder(context, handle));
      },
      popoverBuilder: (context, handle) =>
          _watch(_Spot.popover, widget.popoverBuilder(context, handle)),
    );
  }
}
