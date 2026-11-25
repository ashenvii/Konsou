import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/detail/recommended_titles.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/title_language.dart';

import '../support/detail_rows.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_recommended');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<List<RecommendedTitle>> load(List<LinkedTitle> titles) =>
      loadRecommendedTitles(
        databases,
        titles,
        TitleLanguage.romaji,
        now: DateTime.now(),
      );

  const saved = LinkedTitle(malId: 1, name: 'From MAL 1', note: '412 users');
  const unsaved = LinkedTitle(
    malId: 2,
    name: 'From MAL 2',
    pictureUrl: 'https://example.com/2.jpg',
    note: '9 users',
  );

  test('no titles reads nothing', () async {
    expect(await load(const []), isEmpty);
  });

  test(
    'keeps MAL\'s order, with saved details where Konsou has them',
    () async {
      await addTitle(databases, 1, '2021-01-11', episodes: 11, score: 8.36);
      final titles = await load(const [unsaved, saved]);

      expect([for (final item in titles) item.title.malId], [2, 1]);
      final [loading, loaded] = [for (final item in titles) item.title];
      expect(loading.isLoadingDetails, isTrue);
      expect(loading.name, 'From MAL 2');
      expect(titles.first.pictureUrl, 'https://example.com/2.jpg');
      expect(loaded.isLoadingDetails, isFalse);
      expect(loaded.name, 'Title 1');
      expect((loaded.episodes, loaded.malScore), (11, 8.36));
      expect(titles.last.note, '412 users');
    },
  );

  test('carries the entry of a title on the list', () async {
    await addTitle(databases, 1, '2021-01-11');
    await addEntry(databases, 'e1', malId: 1, status: 'watching', watched: 3);
    final [RecommendedTitle(:title)] = await load(const [saved]);

    expect(
      (title.entryId, title.status, title.episodesWatched),
      ('e1', EntryStatus.watching, 3),
    );
  });

  test('a series on the air counts the episodes out so far', () async {
    await addTitle(
      databases,
      1,
      '2020-01-03',
      airing: 'currently_airing',
      episodes: 12,
    );
    await addTitle(databases, 2, '2027-01-12', airing: 'not_yet_aired');
    final [airing, upcoming] = [
      for (final item in await load(const [saved, unsaved])) item.title,
    ];

    // weekly since 2020, so every episode is out by now
    expect(airing.airedEpisodes, 12);
    expect(upcoming.airedEpisodes, isNull);
    expect(upcoming.isNotAired, isTrue);
  });
}
