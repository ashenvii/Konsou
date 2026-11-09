import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/library/entry_edits.dart';
import 'package:konsou/library/entry_status.dart';

final _now = DateTime.utc(2026, 11, 9, 12);

String _detail({
  String status = 'finished_airing',
  int episodes = 12,
  int seconds = 1440,
}) =>
    '{"title": "T", "status": "$status", "num_episodes": $episodes, '
    '"average_episode_duration": $seconds}';

void main() {
  late Directory folder;
  late Databases databases;
  late int changes;
  late EntryEdits edits;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_entry_edits');
    databases = await openDatabases(folder);
    changes = 0;
    edits = EntryEdits(
      databases: databases,
      onChanged: () => changes++,
      now: () => _now,
    );
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addEntry(
    String id,
    String status, {
    int watched = 0,
    int? malId,
    String? json,
  }) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: id,
            status: status,
            episodesWatched: Value(watched),
            addedAt: 1,
            progressChangedAt: 5,
          ),
        );
    if (malId == null) return;
    await record
        .into(record.entryReference)
        .insert(
          EntryReferenceCompanion.insert(
            entryId: id,
            provider: 'mal',
            providerId: malId,
          ),
        );
    if (json == null) return;
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
  }

  Future<Entry> readEntry(String id) {
    final record = databases.record;
    return (record.select(
      record.entry,
    )..where((row) => row.entryId.equals(id))).getSingle();
  }

  Future<List<Completion>> readCompletions(String id) {
    final record = databases.record;
    return (record.select(record.completion)
          ..where((row) => row.entryId.equals(id))
          ..orderBy([(row) => OrderingTerm.asc(row.watchNumber)]))
        .get();
  }

  group('status', () {
    test('changes the status and times the edit', () async {
      await addEntry('a', 'plan_to_watch');
      final result = await edits.setStatus('a', EntryStatus.onHold);
      expect(result, EditResult.done);
      final entry = await readEntry('a');
      expect(entry.status, 'on_hold');
      expect(entry.progressChangedAt, _now.millisecondsSinceEpoch);
      expect(changes, 1);
    });

    test('the same status changes nothing and tells nobody', () async {
      await addEntry('a', 'watching');
      await edits.setStatus('a', EntryStatus.watching);
      expect((await readEntry('a')).progressChangedAt, 5);
      expect(changes, 0);
    });

    test('an edit is timed after everything already seen', () async {
      await addEntry('a', 'plan_to_watch');
      final record = databases.record;
      await record
          .into(record.device)
          .insert(
            DeviceCompanion.insert(
              deviceId: 'me',
              newestSeenAt: Value(_now.millisecondsSinceEpoch + 9000),
            ),
          );
      await edits.setStatus('a', EntryStatus.onHold);
      expect(
        (await readEntry('a')).progressChangedAt,
        _now.millisecondsSinceEpoch + 9001,
      );
    });

    test('a title that has not aired cannot be watched or completed', () async {
      await addEntry(
        'a',
        'plan_to_watch',
        malId: 1,
        json: _detail(status: 'not_yet_aired'),
      );
      for (final status in [
        EntryStatus.watching,
        EntryStatus.rewatching,
        EntryStatus.completed,
      ]) {
        expect(await edits.setStatus('a', status), EditResult.notAiredYet);
      }
      expect((await readEntry('a')).status, 'plan_to_watch');
      expect(changes, 0);
      expect(await edits.setStatus('a', EntryStatus.onHold), EditResult.done);
    });

    test('an airing title can be watched but not completed', () async {
      await addEntry(
        'a',
        'plan_to_watch',
        malId: 1,
        json: _detail(status: 'currently_airing'),
      );
      expect(
        await edits.setStatus('a', EntryStatus.completed),
        EditResult.stillAiring,
      );
      expect(await edits.setStatus('a', EntryStatus.watching), EditResult.done);
    });

    test('a title with no details yet is not locked', () async {
      await addEntry('a', 'plan_to_watch');
      expect(
        await edits.setStatus('a', EntryStatus.completed),
        EditResult.done,
      );
    });
  });

  group('complete', () {
    test('fills the episodes and logs the finished watch', () async {
      await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      final entry = await readEntry('a');
      expect((entry.status, entry.episodesWatched), ('completed', 12));
      final watches = await readCompletions('a');
      expect(watches, hasLength(1));
      expect(watches.single.watchNumber, 0);
      expect(watches.single.completedAt, _now.millisecondsSinceEpoch);
      expect(watches.single.episodesWatched, 12);
      expect(watches.single.minutesPerEpisode, 24);
      expect(watches.single.isEstimated, isFalse);
    });

    test('an unknown episode count keeps what was watched', () async {
      await addEntry(
        'a',
        'watching',
        watched: 5,
        malId: 1,
        json: '{"status": "finished_airing", "num_episodes": 0}',
      );
      await edits.setStatus('a', EntryStatus.completed);
      expect((await readEntry('a')).episodesWatched, 5);
      expect((await readCompletions('a')).single.minutesPerEpisode, isNull);
    });
  });

  group('episodes', () {
    test('adds one to a title being watched', () async {
      await addEntry('a', 'watching', watched: 3, malId: 1, json: _detail());
      expect(await edits.addEpisode('a'), EditResult.done);
      final entry = await readEntry('a');
      expect((entry.episodesWatched, entry.status), (4, 'watching'));
      expect(entry.progressChangedAt, _now.millisecondsSinceEpoch);
    });

    test('the last episode completes the show', () async {
      await addEntry('a', 'watching', watched: 11, malId: 1, json: _detail());
      await edits.addEpisode('a');
      final entry = await readEntry('a');
      expect((entry.status, entry.episodesWatched), ('completed', 12));
      expect(await readCompletions('a'), hasLength(1));
    });

    test(
      'the last episode of an airing show is added but not completed',
      () async {
        await addEntry(
          'a',
          'watching',
          watched: 11,
          malId: 1,
          json: _detail(status: 'currently_airing'),
        );
        expect(await edits.addEpisode('a'), EditResult.stillAiring);
        final entry = await readEntry('a');
        expect((entry.status, entry.episodesWatched), ('watching', 12));
        expect(await readCompletions('a'), isEmpty);
      },
    );

    test('a rewatch can add episodes too', () async {
      await addEntry('a', 'rewatching', watched: 1, malId: 1, json: _detail());
      expect(await edits.addEpisode('a'), EditResult.done);
      expect((await readEntry('a')).episodesWatched, 2);
    });

    test('only a title being watched takes an episode', () async {
      await addEntry('a', 'plan_to_watch');
      expect(await edits.addEpisode('a'), EditResult.notWatching);
      expect((await readEntry('a')).episodesWatched, 0);
      expect(changes, 0);
    });

    test('nothing is added past a known total', () async {
      await addEntry('a', 'watching', watched: 12, malId: 1, json: _detail());
      await edits.addEpisode('a');
      expect((await readEntry('a')).episodesWatched, 12);
    });
  });

  group('uncheck', () {
    test('goes to Watching when some episodes are watched', () async {
      await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      await edits.uncheck('a');
      final entry = await readEntry('a');
      expect(entry.status, 'watching');
      expect(entry.episodesWatched, 12);
    });

    test('goes to Planned when none are watched', () async {
      await addEntry('a', 'completed');
      await edits.uncheck('a');
      expect((await readEntry('a')).status, 'plan_to_watch');
    });

    test('takes back the finished watch it logged', () async {
      await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      await edits.uncheck('a');
      expect(await readCompletions('a'), isEmpty);
    });

    test('does nothing to a title that is not completed', () async {
      await addEntry('a', 'watching', watched: 2);
      await edits.uncheck('a');
      expect((await readEntry('a')).status, 'watching');
      expect(changes, 0);
    });
  });

  group('leaving completed', () {
    test('any other status takes back the last finished watch', () async {
      await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      await edits.setStatus('a', EntryStatus.onHold);
      expect(await readCompletions('a'), isEmpty);
      expect((await readEntry('a')).status, 'on_hold');
    });

    test('Rewatching from completed is a rewatch', () async {
      await addEntry('a', 'completed', watched: 12);
      await edits.setStatus('a', EntryStatus.rewatching);
      final entry = await readEntry('a');
      expect((entry.status, entry.episodesWatched), ('rewatching', 0));
    });
  });

  group('rewatch', () {
    test('starts again from zero and keeps the old finished watch', () async {
      await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      await edits.rewatch('a');
      final entry = await readEntry('a');
      expect((entry.status, entry.episodesWatched), ('rewatching', 0));
      expect(await readCompletions('a'), hasLength(1));
    });

    test('finishing it logs the next watch', () async {
      await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      await edits.rewatch('a');
      await edits.setStatus('a', EntryStatus.completed);
      final watches = await readCompletions('a');
      expect(watches.map((watch) => watch.watchNumber), [0, 1]);
    });

    test('only a completed title can be rewatched', () async {
      await addEntry('a', 'watching', watched: 2);
      expect(await edits.rewatch('a'), EditResult.notCompleted);
      expect((await readEntry('a')).status, 'watching');
      expect(changes, 0);
    });
  });

  group('remove', () {
    Future<void> fillEverything(String id, int malId) async {
      await addEntry(
        id,
        'completed',
        watched: 12,
        malId: malId,
        json: _detail(),
      );
      final record = databases.record;
      final details = databases.details;
      await record
          .into(record.completion)
          .insert(
            CompletionCompanion.insert(
              entryId: id,
              watchNumber: 0,
              completedAt: 1,
            ),
          );
      await record
          .into(record.alert)
          .insert(
            AlertCompanion.insert(
              entryId: id,
              relatedProvider: 'mal',
              relatedProviderId: 99,
              type: 'sequel',
              createdAt: 1,
            ),
          );
      await record
          .into(record.matchDecline)
          .insert(
            MatchDeclineCompanion.insert(
              entryId: id,
              provider: 'mal',
              providerId: 98,
              declinedAt: 1,
            ),
          );
      await details
          .into(details.matchSuggestion)
          .insert(
            MatchSuggestionCompanion.insert(
              entryId: id,
              provider: 'mal',
              providerId: 97,
              position: 0,
              json: '{}',
              foundAt: 1,
            ),
          );
      await details
          .into(details.matchAttempt)
          .insert(MatchAttemptCompanion.insert(entryId: id, searchedAt: 1));
      await record.customStatement(
        'INSERT INTO details.franchise_link (entry_id, franchise_provider, '
        "franchise_provider_id, is_extra, is_placeholder) VALUES (?, 'mal', 1, 0, 0)",
        [id],
      );
    }

    Future<int> count(String table, String id) async {
      final rows = await databases.record
          .customSelect(
            'SELECT COUNT(*) AS n FROM $table WHERE entry_id = ?',
            variables: [Variable.withString(id)],
          )
          .get();
      return rows.single.read<int>('n');
    }

    test('deletes everything tied to the entry', () async {
      await fillEverything('a', 1);
      await edits.remove(['a']);
      for (final table in [
        'entry',
        'entry_reference',
        'completion',
        'alert',
        'match_decline',
        'details.match_suggestion',
        'details.match_attempt',
        'details.franchise_link',
      ]) {
        expect(await count(table, 'a'), 0, reason: table);
      }
    });

    test('leaves only the removal mark, timed by the edit clock', () async {
      await fillEverything('a', 1);
      await edits.remove(['a']);
      final record = databases.record;
      final marks = await record.select(record.deletion).get();
      expect(marks.map((mark) => mark.entryId), ['a']);
      expect(marks.single.deletedAt, _now.millisecondsSinceEpoch);
    });

    test('removes every entry named and no other', () async {
      await fillEverything('a', 1);
      await fillEverything('b', 2);
      await fillEverything('c', 3);
      await edits.remove(['a', 'b']);
      expect(await count('entry', 'c'), 1);
      expect(await count('completion', 'c'), 1);
      expect(await count('entry', 'a') + await count('entry', 'b'), 0);
      expect(changes, 1);
    });

    test('the cover of a removed entry is left for the pool', () async {
      await fillEverything('a', 1);
      final details = databases.details;
      await details
          .into(details.cover)
          .insert(
            CoverCompanion.insert(
              provider: 'mal',
              providerId: 1,
              size: 'medium',
              url: 'u',
              fileName: 'f',
              bytes: 1,
              fetchedAt: 1,
              shownAt: 1,
            ),
          );
      await edits.remove(['a']);
      expect(await details.select(details.cover).get(), hasLength(1));
    });
  });
}
