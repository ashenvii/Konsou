import 'dart:async';

import 'package:clock/clock.dart';
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
