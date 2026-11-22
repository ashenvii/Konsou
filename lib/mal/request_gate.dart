import 'dart:async';
import 'dart:collection';

import 'package:http/http.dart' as http;

import '../net/backoff.dart';
import '../net/request_timeout.dart';

const requestGap = Duration(milliseconds: 500);

enum Lane { screen, trickle }

class RequestCancelled implements Exception {
  const RequestCancelled();
}

// a screen shows its retry rather than wait minutes behind the trickle's backoff
class GateBackingOff implements Exception {
  const GateBackingOff();
}

class RequestGate {
  RequestGate({
    this.gap = requestGap,
    this.timeout = requestTimeout,
    DateTime Function()? now,
    Future<void> Function(Duration duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  final Duration gap;
  final Duration timeout;
  final DateTime Function() _now;
  final Future<void> Function(Duration duration) _wait;
  final _screen = Queue<_Job>();
  final _trickle = Queue<_Job>();
  var _running = false;
  var _backingOff = false;

  bool get backingOff => _backingOff;
  DateTime? _nextStart;
  final _backoff = Backoff();

  Future<http.Response> send(
    Lane lane,
    Future<http.Response> Function() request, {
    bool Function()? wanted,
  }) {
    final job = _Job(request, wanted);
    if (lane == Lane.screen && _holdsScreenTooLong()) {
      job.done.completeError(const GateBackingOff());
      return job.done.future;
    }
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
      final job = _next();
      if (job == null) continue;
      _nextStart = _now().add(gap);
      try {
        final response = await job.request().timeout(timeout);
        if (response.statusCode == 429 || response.statusCode >= 500) {
          _slowDown();
        } else {
          _backoff.reset();
          _backingOff = false;
        }
        job.done.complete(response);
      } catch (error, stack) {
        _slowDown();
        job.done.completeError(error, stack);
      }
    }
    _running = false;
  }

  _Job? _next() {
    while (_screen.isNotEmpty || _trickle.isNotEmpty) {
      final job = _screen.isNotEmpty
          ? _screen.removeLast()
          : _trickle.removeFirst();
      if (job.wanted?.call() ?? true) return job;
      job.done.completeError(const RequestCancelled());
    }
    return null;
  }

  void _slowDown() {
    _backingOff = true;
    _nextStart = _now().add(_backoff.next());
    if (!_holdsScreenTooLong()) return;
    while (_screen.isNotEmpty) {
      _screen.removeFirst().done.completeError(const GateBackingOff());
    }
  }

  // the first step is short enough to wait out; anything longer is turned away
  bool _holdsScreenTooLong() {
    final nextStart = _nextStart;
    return _backingOff &&
        nextStart != null &&
        nextStart.difference(_now()) > Backoff.first;
  }
}

class _Job {
  _Job(this.request, this.wanted);

  final Future<http.Response> Function() request;
  final bool Function()? wanted;
  final done = Completer<http.Response>();
}
