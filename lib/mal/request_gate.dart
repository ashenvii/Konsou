import 'dart:async';
import 'dart:collection';

import 'package:http/http.dart' as http;

import '../net/backoff.dart';

/// MAL publishes no rate limit; this is the gap its API club asks for,
/// counted from the start of one request to the start of the next.
const requestGap = Duration(milliseconds: 500);

/// Screen requests go ahead of every waiting trickle request.
enum Lane { screen, trickle }

/// Every request to MAL goes through one gate: one at a time, [requestGap]
/// apart, and slower after errors.
class RequestGate {
  RequestGate({
    this.gap = requestGap,
    DateTime Function()? now,
    Future<void> Function(Duration duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  /// Time between the start of one request and the start of the next.
  final Duration gap;
  final DateTime Function() _now;
  final Future<void> Function(Duration duration) _wait;
  final _screen = Queue<_Job>();
  final _trickle = Queue<_Job>();
  var _running = false;
  DateTime? _nextStart;
  final _backoff = Backoff();

  Future<http.Response> send(
    Lane lane,
    Future<http.Response> Function() request,
  ) {
    final job = _Job(request);
    (lane == Lane.screen ? _screen : _trickle).add(job);
    _run();
    return job.done.future;
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    while (_screen.isNotEmpty || _trickle.isNotEmpty) {
      final nextStart = _nextStart;
      if (nextStart != null) {
        final untilNext = nextStart.difference(_now());
        if (untilNext > Duration.zero) await _wait(untilNext);
      }
      // picked after the wait, so a screen request that arrived meanwhile wins
      final job = _screen.isNotEmpty
          ? _screen.removeFirst()
          : _trickle.removeFirst();
      _nextStart = _now().add(gap);
      try {
        final response = await job.request();
        if (response.statusCode == 429 || response.statusCode >= 500) {
          _slowDown();
        } else {
          _backoff.reset();
        }
        job.done.complete(response);
      } catch (error, stack) {
        _slowDown();
        job.done.completeError(error, stack);
      }
    }
    _running = false;
  }

  void _slowDown() => _nextStart = _now().add(_backoff.next());
}

class _Job {
  _Job(this.request);

  final Future<http.Response> Function() request;
  final done = Completer<http.Response>();
}
