import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/app/find_earlier_titles.dart';
import 'package:konsou/library/earlier_titles.dart';
import 'package:konsou/library/title_language.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_earlier');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addTitle(
    int malId,
    String start, {
    String type = 'tv',
    String airing = 'finished_airing',
    List<(int, String)> relations = const [],
    String? entryId,
    String status = 'plan_to_watch',
  }) async {
    final json = jsonEncode({
      'title': 'Title $malId',
      'media_type': type,
      'start_date': start,
      'status': airing,
      'num_episodes': 12,
      'related_anime': [
        for (final (id, type) in relations)
          {
            'node': {'id': id},
            'relation_type': type,
          },
      ],
    });
    final details = databases.details;
    await details
        .into(details.detail)
        .insert(
          DetailCompanion.insert(
            provider: 'mal',
            providerId: malId,
            fetchedAt: 1,
            json: json,
          ),
        );
    if (entryId == null) return;
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: entryId,
            status: status,
            addedAt: 1,
            progressChangedAt: 5,
          ),
        );
    await record
        .into(record.entryReference)
        .insert(
          EntryReferenceCompanion.insert(
            entryId: entryId,
            provider: 'mal',
            providerId: malId,
          ),
        );
  }

  // S1 (1), S2 (2), S3 (3) in a chain, a movie (10) that is a side story of S1
  Future<void> addChain({
    String s1Status = 'plan_to_watch',
    bool s1OnList = true,
    bool s2OnList = false,
  }) async {
    await addTitle(
      1,
      '2019-01-01',
      relations: [(2, 'sequel'), (10, 'side_story')],
      entryId: s1OnList ? 'e1' : null,
      status: s1Status,
    );
    await addTitle(
      2,
      '2020-01-01',
      relations: [(1, 'prequel'), (3, 'sequel')],
      entryId: s2OnList ? 'e2' : null,
    );
    await addTitle(
      3,
      '2021-01-01',
      relations: [(2, 'prequel')],
      entryId: 'e3',
      status: 'completed',
    );
    await addTitle(
      10,
      '2020-06-01',
      type: 'movie',
      relations: [(1, 'parent_story')],
    );
  }

  Future<List<EarlierTitle>> find(String entryId) =>
      findEarlierTitles(databases, entryId, TitleLanguage.romaji);

  test('lists the earlier stories by date, then the earlier extras', () async {
    await addChain();
    final found = await find('e3');
    expect(found.map((title) => title.malId), [1, 2, 10]);
    expect(found.map((title) => title.isExtra), [false, false, true]);
  });

  test('says which are on the list and which are not', () async {
    await addChain();
    final found = await find('e3');
    expect(found.map((title) => title.entryId), ['e1', null, null]);
    expect(found.first.name, 'Title 1');
  });

  test('leaves out titles that are already completed', () async {
    await addChain(s1Status: 'completed');
    expect((await find('e3')).map((title) => title.malId), [2, 10]);
  });

  test('leaves out titles marked rewatching or not interested', () async {
    await addChain(s1Status: 'rewatching', s2OnList: true);
    final record = databases.record;
    await (record.update(record.entry)..where((e) => e.entryId.equals('e2')))
        .write(const EntryCompanion(status: Value('not_interested')));
    expect((await find('e3')).map((title) => title.malId), [10]);
  });

  test('only titles released before the finished one count', () async {
    await addChain();
    expect(await find('e1'), isEmpty);
  });

  test('a title that has not aired is never offered', () async {
    await addChain();
    final details = databases.details;
    await details.customStatement(
      "UPDATE detail SET json = json_set(json, '\$.status', 'not_yet_aired') "
      'WHERE provider_id = 2',
    );
    expect((await find('e3')).map((title) => title.malId), [1, 10]);
  });

  test('a title with no franchise or no details has nothing earlier', () async {
    await addTitle(5, '2020-01-01', entryId: 'solo', status: 'completed');
    expect(await find('solo'), isEmpty);
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: 'bare',
            status: 'completed',
            addedAt: 1,
            progressChangedAt: 5,
          ),
        );
    expect(await find('bare'), isEmpty);
  });
}
