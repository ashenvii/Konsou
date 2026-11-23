import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/detail/watch_order_words.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/library/entry_status.dart';

void main() {
  test('the watch order summary counts the list and the episodes', () {
    expect(
      watchOrderSummary(sampleWatchOrder),
      '2 of 4 on your list · 16 of 40 episodes watched',
    );
  });

  test('a card says the status with its episodes, live ones lit', () {
    final rows = sampleWatchOrder.rows;
    expect(watchOrderState(rows[0]), ('Watching 4 / 28', true));
    // a finished title says only its episodes
    expect(watchOrderState(rows[1]), ('12 ep', false));
    expect(watchOrderState(rows[2]), ('Not aired yet', false));
    expect(watchOrderState(rows[3]), ('', false));
    const planned = WatchOrderRow(
      malId: 9,
      name: 'x',
      isExtra: false,
      status: EntryStatus.planned,
      episodes: 12,
    );
    expect(watchOrderState(planned), ('Planned · 12 ep', false));
  });

  test('the square is named for a screen reader', () {
    final rows = sampleWatchOrder.rows;
    expect(watchOrderStateLabel(rows[0]), 'Watching');
    expect(watchOrderStateLabel(rows[1]), 'Completed');
    expect(watchOrderStateLabel(rows[2]), 'Not aired yet');
    expect(watchOrderStateLabel(rows[3]), 'Loading details');
  });

  test('a card has its date and type beside its number', () {
    final rows = sampleWatchOrder.rows;
    expect(watchOrderWhen(rows[0]), '2023');
    expect(watchOrderMeta(rows[0]), '2023 · TV');
    // still to air: the whole date
    expect(watchOrderWhen(rows[2]), '16 Jan 2026');
  });
}
