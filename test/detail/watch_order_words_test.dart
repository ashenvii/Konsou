import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/detail/watch_order_words.dart';
import 'package:konsou/gallery/detail_section.dart';

void main() {
  test('the watch order summary counts the list and the episodes', () {
    expect(
      watchOrderSummary(sampleWatchOrder),
      '2 of 4 on your list · 16 of 40 episodes watched',
    );
  });

  test('the square is named for a screen reader', () {
    final rows = sampleWatchOrder.rows;
    expect(watchOrderStateLabel(rows[0]), 'Watching');
    expect(watchOrderStateLabel(rows[1]), 'Completed');
    expect(watchOrderStateLabel(rows[2]), 'Not aired yet');
    expect(watchOrderStateLabel(rows[3]), 'Loading details');
  });
}
