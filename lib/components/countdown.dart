import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class Countdown extends ChangeNotifier {
  Countdown({required this.onDone});

  final VoidCallback onDone;

  Duration _total = Duration.zero;
  Duration _left = Duration.zero;
  DateTime? _since;
  Timer? _timer;
  var _disposed = false;

  bool get running => _timer != null;

  bool get started => _total > Duration.zero;

  Duration get total => _total;

  Duration get left {
    final since = _since;
    if (since == null) return _left;
    final left = _left - clock.now().difference(since);
    return left < Duration.zero ? Duration.zero : left;
  }

  double get share =>
      _total == Duration.zero ? 0 : left.inMicroseconds / _total.inMicroseconds;

  void start(Duration total) {
    if (_disposed) return;
    _timer?.cancel();
    _total = total;
    _left = total;
    _run();
  }

  void restart() => start(_total);

  void pause() {
    if (_disposed || !running) return;
    _left = left;
    _timer!.cancel();
    _timer = null;
    _since = null;
    notifyListeners();
  }

  void resume() {
    if (_disposed || running || !started || _left <= Duration.zero) return;
    _run();
  }

  void cancel() {
    // a late call, such as a pointer release after the widget went, is moot
    if (_disposed || (!started && !running)) return;
    _timer?.cancel();
    _timer = null;
    _since = null;
    _total = Duration.zero;
    _left = Duration.zero;
    notifyListeners();
  }

  void _run() {
    _since = clock.now();
    _timer = Timer(_left, _finish);
    notifyListeners();
  }

  void _finish() {
    _timer = null;
    _since = null;
    _left = Duration.zero;
    notifyListeners();
    onDone();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class HoverDelays {
  HoverDelays({required VoidCallback onOpen, required VoidCallback onClose})
    : _opening = Countdown(onDone: onOpen),
      _closing = Countdown(onDone: onClose);

  static const openDelay = Duration(milliseconds: 60);
  static const closeDelay = Duration(milliseconds: 300);

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

mixin HoverDelaysState<T extends StatefulWidget> on State<T> {
  late final hoverDelays = HoverDelays(onOpen: _open, onClose: _close);

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

class CountdownBuilder extends StatefulWidget {
  const CountdownBuilder({
    super.key,
    required this.countdown,
    required this.builder,
  });

  final Countdown countdown;
  final Widget Function(BuildContext context, double share, bool running)
  builder;

  @override
  State<CountdownBuilder> createState() => _CountdownBuilderState();
}

class _CountdownBuilderState extends State<CountdownBuilder>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}));

  @override
  void initState() {
    super.initState();
    widget.countdown.addListener(_changed);
    _followFrames();
  }

  @override
  void didUpdateWidget(CountdownBuilder old) {
    super.didUpdateWidget(old);
    if (old.countdown != widget.countdown) {
      old.countdown.removeListener(_changed);
      widget.countdown.addListener(_changed);
      _followFrames();
    }
  }

  // follow it with frames only while it runs
  void _followFrames() {
    if (widget.countdown.running && !_ticker.isActive) _ticker.start();
    if (!widget.countdown.running && _ticker.isActive) _ticker.stop();
  }

  void _changed() {
    _followFrames();
    setState(() {});
  }

  @override
  void dispose() {
    widget.countdown.removeListener(_changed);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.countdown.share, widget.countdown.running);
}
