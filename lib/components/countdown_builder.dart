import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'countdown.dart';

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
