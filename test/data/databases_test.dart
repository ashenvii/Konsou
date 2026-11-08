import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_db_test');
    databases = await openDatabases(folder);
  });

  // errors from the background isolate arrive wrapped, so match the message
  final refused = throwsA(
    predicate((Object error) => '$error'.contains('CHECK constraint failed')),
  );

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  EntryCompanion entry({String status = 'watching', int? score}) =>
      EntryCompanion.insert(
        entryId: 'legacy-1',
        status: status,
        score: Value(score),
        addedAt: 1700000000000,
        progressChangedAt: 1700000000000,
      );

  Future<void> saveMalReference() {
    final record = databases.record;
    return record
        .into(record.entryReference)
        .insert(
          EntryReferenceCompanion.insert(
            entryId: 'legacy-1',
            provider: 'mal',
            providerId: 52991,
          ),
        );
  }

  test('an entry with a status outside the list is refused', () async {
    final record = databases.record;
    await expectLater(
      record.into(record.entry).insert(entry(status: 'finished')),
      refused,
    );
  });

  test('a score outside 1 to 10 is refused', () async {
    final record = databases.record;
    await expectLater(
      record.into(record.entry).insert(entry(score: 11)),
      refused,
    );
    await expectLater(
      record.into(record.entry).insert(entry(score: 0)),
      refused,
    );
  });

  test(
    'removing an entry drops its references and keeps its completions',
    () async {
      final record = databases.record;
      await record.into(record.entry).insert(entry());
      await saveMalReference();
      await record
          .into(record.completion)
          .insert(
            CompletionCompanion.insert(
              entryId: 'legacy-1',
              watchNumber: 0,
              completedAt: 1700000000000,
            ),
          );

      await record.delete(record.entry).go();

      expect(await record.select(record.entryReference).get(), isEmpty);
      expect(await record.select(record.completion).get(), hasLength(1));
    },
  );

  final frierenJson = File('test/mal/samples/frieren_full.json')
      .readAsStringSync();

  Future<void> saveDetail(String json, {int providerId = 52991}) {
    final details = databases.details;
    return details
        .into(details.detail)
        .insert(
          DetailCompanion.insert(
            provider: 'mal',
            providerId: providerId,
            fetchedAt: 1700000000000,
            json: json,
          ),
        );
  }

  test('detail columns are read out of the saved mal response', () async {
    await saveDetail(frierenJson);
    final details = databases.details;
    final row = await details.select(details.detail).getSingle();
    expect(row.title, 'Sousou no Frieren');
    expect(row.titleEnglish, "Frieren: Beyond Journey's End");
    expect(row.titleJapanese, '葬送のフリーレン');
    expect(row.mediaType, 'tv');
    expect(row.airingStatus, 'finished_airing');
    expect(row.episodes, 28);
    expect(row.startDate, '2023-09-29');
    expect(
      row.coverUrl,
      'https://cdn.myanimelist.net/images/anime/1015/138006l.webp',
    );
    expect(row.nsfw, 'white');
  });

  test('an episode count of 0 from mal reads as unknown', () async {
    await saveDetail(
      frierenJson.replaceFirst('"num_episodes": 28', '"num_episodes": 0'),
    );
    final details = databases.details;
    final row = await details.select(details.detail).getSingle();
    expect(row.episodes, isNull);
  });

  test('one query reads an entry with its title from details.db', () async {
    final record = databases.record;
    await record.into(record.entry).insert(entry());
    await saveMalReference();
    await saveDetail(frierenJson);

    final rows = await record.customSelect('''
      SELECT entry.entry_id, detail.title
      FROM entry
      JOIN entry_reference ON entry_reference.entry_id = entry.entry_id
        AND entry_reference.provider = 'mal'
      JOIN details.detail ON detail.provider = 'mal'
        AND detail.provider_id = entry_reference.provider_id
    ''').get();

    expect(rows.single.data, {
      'entry_id': 'legacy-1',
      'title': 'Sousou no Frieren',
    });
  });
}
