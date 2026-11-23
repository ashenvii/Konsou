import 'package:flutter/widgets.dart';

import 'hover_delays.dart';

mixin HoverDelaysState<T extends StatefulWidget> on State<T> {
  late final hoverDelays = HoverDelays(
    onOpen: _open,
    onClose: _close,
    openDelay: hoverOpenDelay,
  );

  Duration get hoverOpenDelay => HoverDelays.defaultOpenDelay;

  void hoverOpen();

  void hoverClose();

  void _open() {
    if (mounted) hoverOpen();
  }

  void _close() {
    if (mounted) hoverClose();
  }

  @override
  void dispose() {
    hoverDelays.dispose();
    super.dispose();
  }
}
