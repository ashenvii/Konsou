import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/net/drain_queue.dart';

void main() {
  test('reports each item once it has been worked', () async {
    final left = [1, 2, 3];
    final done = <int>[];
    final reported = <int>[];
    final finished = await drainQueue<int>(
      tag: 'test',
      isStopped: () => false,
      next: (skip) async => left.isEmpty ? null : left.first,
      work: (item) async {
        left.remove(item);
        done.add(item);
        return false;
      },
      onItem: () => reported.add(done.length),
    );
    expect(finished, (finished: true, leftBehind: false));
    expect(reported, [1, 2, 3]);
  });

  test('says when a failed item was left behind', () async {
    final run = await drainQueue<int>(
      tag: 'test',
      isStopped: () => false,
      next: (skip) async => skip.contains(1) ? null : 1,
      work: (item) async => true,
    );
    expect(run, (finished: true, leftBehind: true));
  });

  test('an item that throws is skipped and the others still run', () async {
    final left = [1, 2, 3];
    final done = <int>[];
    final run = await drainQueue<int>(
      tag: 'test',
      isStopped: () => false,
      next: (skip) async {
        final open = left.where((item) => !skip.contains(item));
        return open.isEmpty ? null : open.first;
      },
      work: (item) async {
        if (item == 2) throw StateError('broken');
        left.remove(item);
        done.add(item);
        return false;
      },
    );
    expect(run, (finished: true, leftBehind: true));
    expect(done, [1, 3]);
  });
}
