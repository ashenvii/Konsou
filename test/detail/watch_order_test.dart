import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/title_language.dart';

import '../support/detail_rows.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_watch_order');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<WatchOrder> load(int malId) =>
      loadWatchOrder(databases, malId, TitleLanguage.romaji);

  // S1 (1), S2 (2), S3 (3) in a chain, a movie (10) between S2 and S3 that is
  // a side story of S1
  Future<void> addChain() async {
    await addTitle(
      databases,
      1,
      '2019-01-01',
      relations: [relate(2, 'sequel'), relate(10, 'side_story')],
    );
    await addTitle(
      databases,
      2,
      '2020-01-01',
      episodes: 24,
      relations: [relate(1, 'prequel'), relate(3, 'sequel')],
    );
    await addTitle(
      databases,
      3,
      null,
      airing: 'not_yet_aired',
      episodes: 0,
      relations: [relate(2, 'prequel')],
    );
    await addTitle(
      databases,
      10,
      '2020-06-01',
      type: 'movie',
      episodes: 1,
      relations: [relate(1, 'parent_story')],
    );
  }

  test('stories in release order, each extra by its own date', () async {
    await addChain();
    final order = await load(2);

    expect([for (final row in order.rows) row.malId], [1, 2, 10, 3]);
    expect(
      [for (final row in order.rows) row.isExtra],
      [false, false, true, false],
    );
    expect(order.rows[1].isOpenTitle, isTrue);
    expect(order.rows[2].mediaType, 'movie');
    expect(order.rows[0].name, 'Title 1');
    expect(order.rows[0].startDate, '2019-01-01');
  });

  test('a title not aired yet says so and has no episode count', () async {
    await addChain();
    final upcoming = (await load(1)).rows.last;

    expect(upcoming.malId, 3);
    expect(upcoming.isNotAired, isTrue);
    expect(upcoming.episodes, isNull);
    expect(upcoming.startDate, isNull);
  });

  test('carries the status and progress of titles on the list', () async {
    await addChain();
    await addEntry(databases, 'e1', malId: 1, status: 'completed', watched: 12);
    await addEntry(databases, 'e2', malId: 2, status: 'watching', watched: 5);
    final order = await load(1);

    final first = order.rows[0];
    expect(
      (first.entryId, first.status, first.episodesWatched),
      ('e1', EntryStatus.completed, 12),
    );
    expect(order.rows[1].status, EntryStatus.watching);
    expect(order.rows[2].entryId, isNull);
    expect(order.rows[2].status, isNull);
  });

  test('the summary counts titles on the list and episodes watched', () async {
    await addChain();
    await addEntry(databases, 'e1', malId: 1, status: 'rewatching', watched: 2);
    await addEntry(databases, 'e2', malId: 2, status: 'watching', watched: 5);
    final order = await load(1);

    expect((order.onList, order.rows.length), (2, 4));
    // a rewatch has seen all 12 of S1
    expect((order.episodesWatched, order.episodesTotal), (17, 37));
  });

  test('of two entries on one page, the one changed last shows', () async {
    await addChain();
    await addEntry(databases, 'old', malId: 1, status: 'dropped', changedAt: 5);
    await addEntry(
      databases,
      'new',
      malId: 1,
      status: 'watching',
      changedAt: 9,
    );

    expect((await load(1)).rows.first.entryId, 'new');
  });

  test('a title with no franchise has no watch order', () async {
    await addTitle(databases, 1, '2019-01-01');
    await addTitle(databases, 2, '2020-01-01');

    expect((await load(1)).rows, isEmpty);
    expect((await load(404)).rows, isEmpty);
  });

  test('a related title not fetched yet shows as loading details', () async {
    await addTitle(
      databases,
      1,
      '2019-01-01',
      relations: [
        relate(
          2,
          'sequel',
          node: {
            'title': 'Season 2',
            'media_type': 'tv',
            'start_date': '2020-01-01',
            'num_episodes': 13,
            'status': 'not_yet_aired',
          },
        ),
        relate(10, 'side_story', node: {'title': 'The OVA'}),
        relate(20, 'spin_off', node: {'title': 'Spin-off'}),
        relate(30, 'side_story', node: {'title': 'Gone'}),
      ],
    );
    final details = databases.details;
    await details
        .into(details.gonePage)
        .insert(
          GonePageCompanion.insert(
            provider: 'mal',
            providerId: 30,
            checkedAt: 1,
          ),
        );
    final order = await load(1);

    // the undated OVA goes last
    expect([for (final row in order.rows) row.malId], [1, 2, 10]);
    final sequel = order.rows[1];
    expect(sequel.isLoadingDetails, isTrue);
    expect(
      (sequel.name, sequel.isExtra, sequel.episodes, sequel.isNotAired),
      ('Season 2', false, 13, true),
    );
    expect(order.rows[2].isExtra, isTrue);
    expect(order.rows.first.isLoadingDetails, isFalse);
  });

  test('an extra does not pull in its own sequels', () async {
    await addChain();
    await addTitle(
      databases,
      11,
      '2020-07-01',
      type: 'ova',
      relations: [relate(1, 'parent_story'), relate(99, 'sequel')],
    );

    expect(
      [for (final row in (await load(1)).rows) row.malId],
      [1, 2, 10, 11, 3],
    );
  });

  test('names follow the title language', () async {
    await addTitle(
      databases,
      1,
      '2019-01-01',
      english: 'English One',
      relations: [relate(2, 'sequel')],
    );
    await addTitle(
      databases,
      2,
      '2020-01-01',
      relations: [relate(1, 'prequel')],
    );
    final order = await loadWatchOrder(databases, 1, TitleLanguage.english);

    expect(
      [for (final row in order.rows) row.name],
      ['English One', 'Title 2'],
    );
  });
}
