import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/library/title_language.dart';

final _now = DateTime.utc(2026, 11, 14, 12);

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_title_details');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> save(String sample, {required bool full, DateTime? at}) =>
      databases.details
          .into(databases.details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: 52991,
              fetchedAt: (at ?? _now).millisecondsSinceEpoch,
              json: File('test/mal/samples/$sample.json').readAsStringSync(),
              isFull: Value(full),
            ),
          );

  Future<TitleDetails> read([
    TitleLanguage language = TitleLanguage.romaji,
  ]) async => (await readTitleDetails(databases, 52991, language))!;

  test('a title with no saved details reads as nothing', () async {
    expect(
      await readTitleDetails(databases, 52991, TitleLanguage.romaji),
      isNull,
    );
  });

  test(
    'the header: names, score, completed share and the list counts',
    () async {
      await save('frieren_full', full: true);
      final details = await read();

      expect(details.name, 'Sousou no Frieren');
      expect(details.otherName, "Frieren: Beyond Journey's End");
      expect(details.otherNames, [
        '葬送のフリーレン',
        'Frieren at the Funeral',
        'Frieren The Slayer',
      ]);
      expect((details.score, details.rank, details.popularity), (9.24, 1, 95));
      expect(details.listUsers, 1541014);
      final counts = details.listCounts!;
      expect(
        (
          counts.watching,
          counts.completed,
          counts.onHold,
          counts.dropped,
          counts.planned,
        ),
        (242405, 1020871, 31940, 26060, 219738),
      );
      expect(details.completedShare, closeTo(0.6625, 0.0001));
    },
  );

  test('the other main title is romaji under an English name', () async {
    await save('frieren_full', full: true);
    final english = await read(TitleLanguage.english);
    expect(english.name, "Frieren: Beyond Journey's End");
    expect(english.otherName, 'Sousou no Frieren');

    final japanese = await read(TitleLanguage.japanese);
    expect(japanese.name, '葬送のフリーレン');
    expect(japanese.otherName, 'Sousou no Frieren');
    expect(japanese.otherNames.first, "Frieren: Beyond Journey's End");
  });

  test('the overview facts', () async {
    await save('frieren_full', full: true);
    final details = await read();

    expect((details.mediaType, details.episodes), ('tv', 28));
    expect((details.startDate, details.endDate), ('2023-09-29', '2024-03-22'));
    expect((details.season, details.seasonYear), ('fall', 2023));
    expect((details.broadcastDay, details.broadcastTime), ('friday', '23:00'));
    expect(details.secondsPerEpisode, 1470);
    expect((details.source, details.rating), ('manga', 'pg_13'));
    expect(details.studios, ['Madhouse']);
    expect(details.genres, contains('Adventure'));
    expect(details.synopsis, isNotNull);
    expect(details.background, isNotNull);
    expect(details.nsfw, 'white');
    expect(details.airingStatus, 'finished_airing');
  });

  test('a short row holds no score, counts or synopsis', () async {
    await save('frieren_short', full: false);
    final details = await read();

    expect(details.isFull, isFalse);
    expect(details.name, 'Sousou no Frieren');
    expect(details.score, isNull);
    expect(details.listCounts, isNull);
    expect(details.completedShare, isNull);
    expect(details.synopsis, isNull);
    expect(details.studios, isEmpty);
  });

  test(
    'a short or stale row needs a fetch, a fresh full one does not',
    () async {
      await save('frieren_full', full: true);
      expect((await read()).needsFetch(_now), isFalse);
      expect(
        (await read()).needsFetch(_now.add(const Duration(days: 31))),
        isTrue,
      );

      await databases.details.delete(databases.details.detail).go();
      await save('frieren_short', full: false);
      expect((await read()).needsFetch(_now), isTrue);
    },
  );
}
