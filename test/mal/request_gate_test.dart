import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:konsou/mal/request_gate.dart';

/// A clock that only moves when the gate waits, so start times are exact.
class _FakeTime {
  var now = DateTime.utc(2026, 11, 8);
  final starts = <int>[];
  late final DateTime begin = now;

  Future<void> wait(Duration duration) async => now = now.add(duration);

  Future<http.Response> respond(int status) async {
    starts.add(now.difference(begin).inMilliseconds);
    return http.Response('', status);
  }
}

void main() {
  late _FakeTime time;
  late RequestGate gate;

  setUp(() {
    time = _FakeTime();
    gate = RequestGate(now: () => time.now, wait: time.wait);
  });

  test('requests start at least the request gap apart', () async {
    await Future.wait([
      gate.send(Lane.trickle, () => time.respond(200)),
      gate.send(Lane.trickle, () => time.respond(200)),
      gate.send(Lane.trickle, () => time.respond(200)),
    ]);
    expect(requestGap, const Duration(milliseconds: 500));
    expect(time.starts, [0, 500, 1000]);
  });

  test('a screen request goes ahead of waiting trickle requests', () async {
    final order = <String>[];
    Future<http.Response> named(String name) {
      order.add(name);
      return time.respond(200);
    }

    await Future.wait([
      gate.send(Lane.trickle, () => named('trickle 1')),
      gate.send(Lane.trickle, () => named('trickle 2')),
      gate.send(Lane.screen, () => named('screen')),
    ]);
    expect(order, ['trickle 1', 'screen', 'trickle 2']);
  });

  test('server errors double the wait and a success resets it', () async {
    for (final status in [500, 429, 200, 200, 503]) {
      await gate.send(Lane.trickle, () => time.respond(status));
    }
    await gate.send(Lane.trickle, () => time.respond(200));
    expect(time.starts, [0, 5000, 15000, 15500, 16000, 21000]);
  });

  test('the wait stops growing at 10 minutes', () async {
    for (var i = 0; i < 9; i++) {
      await gate.send(Lane.trickle, () => time.respond(500));
    }
    final waits = [
      for (var i = 1; i < time.starts.length; i++)
        time.starts[i] - time.starts[i - 1],
    ];
    expect(waits, [5, 10, 20, 40, 80, 160, 320, 600].map((s) => s * 1000));
  });

  test('a network error slows the gate and reaches the caller', () async {
    await expectLater(
      gate.send(Lane.trickle, () async {
        time.starts.add(time.now.difference(time.begin).inMilliseconds);
        throw const SocketException('no network');
      }),
      throwsA(isA<SocketException>()),
    );
    await gate.send(Lane.trickle, () => time.respond(200));
    expect(time.starts, [0, 5000]);
  });

  test('a 404 does not slow the gate', () async {
    await gate.send(Lane.trickle, () => time.respond(404));
    await gate.send(Lane.trickle, () => time.respond(200));
    expect(time.starts, [0, 500]);
  });
}
