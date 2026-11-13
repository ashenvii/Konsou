import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/detail/provider_page.dart';
import 'package:konsou/detail/streamer_mode.dart';
import 'package:konsou/detail/title_entry.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/title_language.dart';

import '../support/detail_rows.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_title_entry');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  group('the entry', () {
    test(
      'reads the user\'s side of a title, finished watches oldest first',
      () async {
        await addEntry(
          databases,
          'a',
          malId: 7,
          status: 'completed',
          watched: 12,
        );
        final record = databases.record;
        await (record.update(record.entry)).write(
          const EntryCompanion(
            score: Value(9),
            notes: Value('Twice'),
            startedAt: Value(1000),
          ),
        );
        for (final (number, at, estimated) in [
          (1, 300, false),
          (0, 100, true),
        ]) {
          await record
              .into(record.completion)
              .insert(
                CompletionCompanion.insert(
                  entryId: 'a',
                  watchNumber: number,
                  completedAt: at,
                  isEstimated: Value(estimated),
                ),
              );
        }
        final entry = (await readEntry(databases, 'a'))!;

        expect(
          (entry.status, entry.episodesWatched),
          (EntryStatus.completed, 12),
        );
        expect((entry.score, entry.notes, entry.startedAt), (9, 'Twice', 1000));
        expect((entry.malId, entry.isNotLinked), (7, false));
        expect(
          [
            for (final watch in entry.finishedWatches)
              (watch.watchNumber, watch.completedAt, watch.isEstimated),
          ],
          [(0, 100, true), (1, 300, false)],
        );
      },
    );

    test('a not-linked entry is read by its saved name', () async {
      await addEntry(databases, 'a', name: 'Scott Pilgrim Takes Off');
      final entry = (await readEntry(databases, 'a'))!;

      expect(entry.name, 'Scott Pilgrim Takes Off');
      expect(entry.isNotLinked, isTrue);
      expect(await readEntry(databases, 'missing'), isNull);
    });

    test('a page with no entry is not on the list', () async {
      expect(await readEntryOnPage(databases, 7), isNull);
    });

    test(
      'of two entries on one page, the one opened wins, else the newest',
      () async {
        await addEntry(databases, 'old', malId: 7, changedAt: 5);
        await addEntry(databases, 'new', malId: 7, changedAt: 9);
        await addEntry(databases, 'other', malId: 8, changedAt: 20);

        expect((await readEntryOnPage(databases, 7))!.entryId, 'new');
        expect(
          (await readEntryOnPage(databases, 7, preferred: 'old'))!.entryId,
          'old',
        );
        // an entry that sits on another page is not preferred here
        expect(
          (await readEntryOnPage(databases, 7, preferred: 'other'))!.entryId,
          'new',
        );
      },
    );
  });

  group('the page picker', () {
    test(
      'suggestions come back in order, named in the title language',
      () async {
        final details = databases.details;
        final pages = [
          {
            'id': 9,
            'title': 'Second',
            'alternative_titles': {'en': 'Second in English', 'ja': ''},
            'media_type': 'movie',
            'start_date': '2021-05-01',
            'num_episodes': 1,
            'main_picture': {'medium': 'https://example.test/9.jpg'},
          },
          {'id': 4, 'title': 'First', 'num_episodes': 0},
        ];
        for (final (position, page) in [(1, pages[0]), (0, pages[1])]) {
          await details
              .into(details.matchSuggestion)
              .insert(
                MatchSuggestionCompanion.insert(
                  entryId: 'a',
                  provider: 'mal',
                  providerId: page['id']! as int,
                  position: position,
                  json: jsonEncode(page),
                  foundAt: 1,
                ),
              );
        }
        final found = await readSuggestions(
          databases,
          'a',
          TitleLanguage.english,
        );

        expect([for (final page in found) page.malId], [4, 9]);
        expect(
          (found[0].name, found[0].episodes, found[0].coverUrl),
          ('First', null, null),
        );
        final second = found[1];
        expect(second.name, 'Second in English');
        expect(
          (second.mediaType, second.startDate, second.episodes),
          ('movie', '2021-05-01', 1),
        );
        expect(second.coverUrl, 'https://example.test/9.jpg');
        expect(
          await readSuggestions(databases, 'b', TitleLanguage.romaji),
          isEmpty,
        );
      },
    );
  });

  group('Streamer mode', () {
    test('hides an adult title only while it is on', () {
      bool hidden(String? nsfw, {bool on = true}) =>
          isHiddenInStreamerMode(streamerMode: on, nsfw: nsfw);

      expect(hidden('black'), isTrue);
      expect(hidden('gray'), isTrue);
      expect(hidden('white'), isFalse);
      expect(hidden(null), isFalse);
      expect(hidden('black', on: false), isFalse);
    });

    test('is off until it is stored as on', () async {
      final record = databases.record;
      expect(await readStreamerMode(record), isFalse);
      await record
          .into(record.setting)
          .insert(SettingCompanion.insert(key: streamerModeKey, value: 'true'));
      expect(await readStreamerMode(record), isTrue);
    });
  });
}
