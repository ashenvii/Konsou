import 'dart:async';
import 'dart:collection';

import 'package:http/http.dart' as http;

import '../net/backoff.dart';

const requestGap = Duration(milliseconds: 500);

enum Lane { screen, trickle }

class RequestCancelled implements Exception {
  const RequestCancelled();
}

class RequestGate {
  RequestGate({
    this.gap = requestGap,
    DateTime Function()? now,
    Future<void> Function(Duration duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

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
    Future<http.Response> Function() request, {
    bool Function()? wanted,
  }) {
    final job = _Job(request, wanted);
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

  void _slowDown() => _nextStart = _now().add(_backoff.next());
}

class _Job {
  _Job(this.request, this.wanted);

  final Future<http.Response> Function() request;
  final bool Function()? wanted;
  final done = Completer<http.Response>();
}
