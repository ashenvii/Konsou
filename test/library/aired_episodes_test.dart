import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/aired_episodes.dart';

void main() {
  int? count(
    DateTime now, {
    String airing = 'currently_airing',
    String type = 'tv',
    String? start = '2026-10-02',
    String? time = '23:00',
    int? total = 12,
  }) => countAiredEpisodes(
    airingStatus: airing,
    mediaType: type,
    startDate: start,
    broadcastTime: time,
    total: total,
    now: now,
  );

  test('one episode a week from the first broadcast, in Japan time', () {
    // 23:00 in Japan on 2 October is 14:00 UTC
    expect(count(DateTime.utc(2026, 10, 2, 13, 59)), 0);
    expect(count(DateTime.utc(2026, 10, 2, 14)), 1);
    expect(count(DateTime.utc(2026, 10, 9, 13, 59)), 1);
    expect(count(DateTime.utc(2026, 10, 9, 14)), 2);
    expect(count(DateTime.utc(2026, 11, 14)), 7);
  });

  test('never more than the total', () {
    expect(count(DateTime.utc(2027, 6, 1)), 12);
    expect(count(DateTime.utc(2027, 6, 1), total: null), 35);
  });

  test('no broadcast time counts from midnight in Japan', () {
    expect(count(DateTime.utc(2026, 10, 1, 15), time: null), 1);
    expect(count(DateTime.utc(2026, 10, 1, 14, 59), time: null), 0);
  });

  test('nothing has aired of a title not aired yet', () {
    expect(count(DateTime.utc(2026, 11, 14), airing: 'not_yet_aired'), 0);
  });

  test('cannot be told for a finished title, another type or a loose date', () {
    final now = DateTime.utc(2026, 11, 14);
    expect(count(now, airing: 'finished_airing'), isNull);
    expect(count(now, type: 'ona'), isNull);
    expect(count(now, start: '2026-10'), isNull);
    expect(count(now, start: null), isNull);
  });
}
