import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/net/drain_queue.dart';

void main() {
  test('reports each item once it has been worked', () async {
    final left = [1, 2, 3];
    final done = <int>[];
    final reported = <int>[];
    final finished = await drainQueue<int>(
      isStopped: () => false,
      next: (skip) async => left.isEmpty ? null : left.first,
      work: (item) async {
        left.remove(item);
        done.add(item);
        return false;
      },
      onItem: () => reported.add(done.length),
    );
    expect(finished, isTrue);
    expect(reported, [1, 2, 3]);
  });
}
