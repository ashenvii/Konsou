import 'dart:math';

/// How long to wait after a failed request: 5 seconds, doubling with each
/// failure in a row, up to 10 minutes. A success starts it over.
class Backoff {
  static const first = Duration(seconds: 5);
  static const longest = Duration(minutes: 10);

  Duration? _current;

  Duration next() {
    final previous = _current;
    final wait = previous == null
        ? first
        : Duration(
            microseconds: min(
              previous.inMicroseconds * 2,
              longest.inMicroseconds,
            ),
          );
    _current = wait;
    return wait;
  }

  void reset() => _current = null;
}
