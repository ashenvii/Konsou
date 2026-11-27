import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../net/backoff.dart';
import '../net/log.dart';

const requestGap = Duration(milliseconds: 500);

/// How long the API gate waits on a request. MAL answers in well under a
/// second when it answers; about 1 in 80 never did in the owner's log, and
/// each of those held the queue for the old 30 s.
const malRequestTimeout = Duration(seconds: 15);

// flutter's kDebugMode, spelled out since lib/mal stays plain dart
const _debugBuild =
    !bool.fromEnvironment('dart.vm.product') &&
    !bool.fromEnvironment('dart.vm.profile');

/// Who is asking, in the order they are served: [page] is what the user just
/// opened or typed, [screen] is what the cards and strips on show want,
/// [trickle] is the background.
enum Lane { page, screen, trickle }

/// Fake trouble for every gate, set from the gallery to see the app's
/// offline and waiting states. Debug builds only.
enum MalTrouble {
  normal,

  /// Never answers, so each request runs into the timeout.
  slow,
  rateLimited,
  offline,
}

class RequestCancelled implements Exception {
  const RequestCancelled();
}

// a screen shows its retry rather than wait minutes behind the trickle's backoff
class GateBackingOff implements Exception {
  const GateBackingOff();
}

class RequestGate {
  RequestGate({
    this.name = 'mal',
    this.gap = requestGap,
    this.timeout = malRequestTimeout,
    DateTime Function()? now,
    Future<void> Function(Duration duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  static var trouble = MalTrouble.normal;

  final String name;
  final Duration gap;
  final Duration timeout;
  final DateTime Function() _now;
  final Future<void> Function(Duration duration) _wait;
  final _page = Queue<_Job>();
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
    if (lane != Lane.trickle && _holdsScreenTooLong()) {
      log(name, '${lane.name} request turned away, backing off');
      job.done.completeError(const GateBackingOff());
      return job.done.future;
    }
    switch (lane) {
      case Lane.page:
        _page.add(job);
      case Lane.screen:
        _screen.add(job);
      case Lane.trickle:
        _trickle.add(job);
    }
    _run();
    return job.done.future;
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    while (_page.isNotEmpty || _screen.isNotEmpty || _trickle.isNotEmpty) {
      final nextStart = _nextStart;
      if (nextStart != null) {
        final untilNext = nextStart.difference(_now());
        if (untilNext > Duration.zero) await _wait(untilNext);
      }
      // picked after the wait, so a page or screen request that arrived meanwhile wins
      final job = _next();
      if (job == null) continue;
      _nextStart = _now().add(gap);
      try {
        final response = await _start(job).timeout(timeout);
        if (response.statusCode == 429 || response.statusCode >= 500) {
          log(name, 'status ${response.statusCode}');
          _slowDown();
        } else {
          _backoff.reset();
          _backingOff = false;
        }
        job.done.complete(response);
      } catch (error, stack) {
        log(name, 'request failed: ${error.runtimeType}');
        _slowDown();
        job.done.completeError(error, stack);
      }
    }
    _running = false;
  }

  Future<http.Response> _start(_Job job) {
    if (!_debugBuild) return job.request();
    return switch (trouble) {
      MalTrouble.normal => job.request(),
      MalTrouble.slow => Completer<http.Response>().future,
      MalTrouble.rateLimited => Future.value(http.Response('', 429)),
      MalTrouble.offline => Future.error(
        const SocketException('fake trouble: offline'),
      ),
    };
  }

  _Job? _next() {
    while (_page.isNotEmpty || _screen.isNotEmpty || _trickle.isNotEmpty) {
      // the page's own requests keep their order; on the screen the newest
      // card is the one being looked at
      final job = _page.isNotEmpty
          ? _page.removeFirst()
          : _screen.isNotEmpty
          ? _screen.removeLast()
          : _trickle.removeFirst();
      if (job.wanted?.call() ?? true) return job;
      job.done.completeError(const RequestCancelled());
    }
    return null;
  }

  void _slowDown() {
    _backingOff = true;
    final wait = _backoff.next();
    _nextStart = _now().add(wait);
    log(name, 'backing off ${wait.inSeconds} s');
    if (!_holdsScreenTooLong()) return;
    for (final queue in [_page, _screen]) {
      while (queue.isNotEmpty) {
        queue.removeFirst().done.completeError(const GateBackingOff());
      }
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
