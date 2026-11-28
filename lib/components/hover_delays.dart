import 'package:flutter/widgets.dart';

import 'countdown.dart';

/// Opens after a short hover and closes after a grace time, so the pointer can
/// cross onto a popover.
class HoverDelays {
  HoverDelays({
    required VoidCallback onOpen,
    required VoidCallback onClose,
    this.openDelay = defaultOpenDelay,
  }) : _opening = Countdown(onDone: onOpen),
       _closing = Countdown(onDone: onClose);

  static const defaultOpenDelay = Duration(milliseconds: 60);
  // long enough to cross from the anchor onto the popover, no longer
  static const closeDelay = Duration(milliseconds: 100);

  final Duration openDelay;
  final Countdown _opening;
  final Countdown _closing;

  void entered({required bool isOpen}) {
    _closing.cancel();
    if (!isOpen && !_opening.running) _opening.start(openDelay);
  }

  void left({required bool isOpen}) {
    _opening.cancel();
    if (isOpen && !_closing.running) _closing.start(closeDelay);
  }

  void dispose() {
    _opening.dispose();
    _closing.dispose();
  }
}
