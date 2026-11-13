import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/library/earlier_titles.dart';
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

  group('undo', () {
    test(
      'puts back the status, the episodes and removes the logged watch',
      () async {
        await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
        final undo = await edits.snapshot(['a']);
        await edits.setStatus('a', EntryStatus.completed);
        await undo.run();
        final entry = await readEntry('a');
        expect((entry.status, entry.episodesWatched), ('watching', 5));
        expect(await readCompletions('a'), isEmpty);
      },
    );

    test('brings back a finished watch that was taken back', () async {
      await addEntry('a', 'watching', watched: 5, malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      final undo = await edits.snapshot(['a']);
      await edits.uncheck('a');
      expect(await readCompletions('a'), isEmpty);
      await undo.run();
      expect((await readEntry('a')).status, 'completed');
      expect(await readCompletions('a'), hasLength(1));
    });

    test(
      'is a new edit: timed after the one it takes back, and synced',
      () async {
        var tick = 0;
        edits = EntryEdits(
          databases: databases,
          onChanged: () => changes++,
          now: () => _now.add(Duration(seconds: tick++)),
        );
        await addEntry('a', 'watching', watched: 5);
        final undo = await edits.snapshot(['a']);
        await edits.setStatus('a', EntryStatus.onHold);
        final before = (await readEntry('a')).progressChangedAt;
        changes = 0;
        await undo.run();
        expect((await readEntry('a')).progressChangedAt, greaterThan(before));
        expect(changes, 1);
      },
    );
  });

  group('score', () {
    test('sets, replaces and clears the score, timed on its own', () async {
      await addEntry('a', 'completed');
      await edits.setScore('a', 8);
      var entry = await readEntry('a');
      expect(entry.score, 8);
      expect(entry.scoreChangedAt, _now.millisecondsSinceEpoch);
      expect(entry.progressChangedAt, 5);
      await edits.setScore('a', null);
      entry = await readEntry('a');
      expect(entry.score, isNull);
      expect(changes, 2);
    });
  });

  group('earlier titles', () {
    EarlierTitle earlier(int malId, {String? entryId, int? episodes = 12}) =>
        EarlierTitle(
          malId: malId,
          entryId: entryId,
          name: 'T$malId',
          isExtra: false,
          episodes: episodes,
        );

    test('marks a title on the list as an estimated finished watch', () async {
      await addEntry('a', 'plan_to_watch', malId: 1, json: _detail());
      await edits.markEarlier([earlier(1, entryId: 'a')]);
      final entry = await readEntry('a');
      expect((entry.status, entry.episodesWatched), ('completed', 12));
      final watch = (await readCompletions('a')).single;
      expect(watch.isEstimated, isTrue);
      expect(watch.completedAt, _now.millisecondsSinceEpoch);
      expect(watch.watchNumber, 0);
      expect(changes, 1);
    });

    test('adds a title that is not on the list as Completed', () async {
      final record = databases.record;
      await databases.details
          .into(databases.details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: 7,
              fetchedAt: 1,
              json: _detail(episodes: 24),
            ),
          );
      await edits.markEarlier([earlier(7, episodes: 24)]);
      final entries = await record.select(record.entry).get();
      expect(entries, hasLength(1));
      final entry = entries.single;
      expect((entry.status, entry.episodesWatched), ('completed', 24));
      expect(entry.name, isNull);
      final refs = await record.select(record.entryReference).get();
      expect((refs.single.entryId, refs.single.providerId), (entry.entryId, 7));
      expect((await readCompletions(entry.entryId)).single.isEstimated, isTrue);
    });

    test('undo takes the whole batch back, including added titles', () async {
      await addEntry('a', 'plan_to_watch', malId: 1, json: _detail());
      await databases.details
          .into(databases.details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: 7,
              fetchedAt: 1,
              json: _detail(),
            ),
          );
      final mark = await edits.markEarlier([
        earlier(1, entryId: 'a'),
        earlier(7),
      ]);
      await mark.undo.run();
      final record = databases.record;
      expect(await record.select(record.entry).get(), hasLength(1));
      expect((await readEntry('a')).status, 'plan_to_watch');
      expect(await readCompletions('a'), isEmpty);
    });

    test(
      'a non-Completed status sets only the status and keeps episodes',
      () async {
        await addEntry('a', 'plan_to_watch', malId: 1, json: _detail());
        final mark = await edits.markEarlier([
          earlier(1, entryId: 'a'),
        ], status: EntryStatus.dropped);
        expect(mark.applied, 1);
        final entry = await readEntry('a');
        expect((entry.status, entry.episodesWatched), ('dropped', 0));
        expect(await readCompletions('a'), isEmpty);
      },
    );

    test('an unlisted title can be added as Not interested', () async {
      await databases.details
          .into(databases.details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: 9,
              fetchedAt: 1,
              json: _detail(),
            ),
          );
      await edits.markEarlier([earlier(9)], status: EntryStatus.notInterested);
      final record = databases.record;
      final entry = (await record.select(record.entry).get()).single;
      expect(entry.status, 'not_interested');
      expect(await readCompletions(entry.entryId), isEmpty);
    });

    test(
      'moving a completed title to another status takes its completion back',
      () async {
        await addEntry('a', 'completed');
        await edits.markEarlier([
          earlier(1, entryId: 'a'),
        ], status: EntryStatus.onHold);
        expect((await readEntry('a')).status, 'on_hold');
        expect(await readCompletions('a'), isEmpty);
      },
    );

    test('a title already in the chosen status is not counted', () async {
      await addEntry('a', 'completed');
      final mark = await edits.markEarlier([earlier(1, entryId: 'a')]);
      expect(mark.applied, 0);
      expect((await readEntry('a')).status, 'completed');
    });

    test('Not now saves one earlier_unmarked alert per title, once', () async {
      await addEntry('a', 'completed');
      final titles = [earlier(1), earlier(2)];
      await edits.saveEarlierUnmarked('a', titles);
      await edits.saveEarlierUnmarked('a', titles);
      final record = databases.record;
      final alerts = await record.select(record.alert).get();
      expect(
        alerts.map((alert) => alert.relatedProviderId),
        unorderedEquals([1, 2]),
      );
      expect(alerts.every((alert) => alert.type == 'earlier_unmarked'), isTrue);
      expect(alerts.every((alert) => alert.entryId == 'a'), isTrue);
    });

    test('the auto-mark setting is off until it is stored as on', () async {
      expect(await edits.readAutoMarkEarlier(), isFalse);
      final record = databases.record;
      await record
          .into(record.setting)
          .insert(
            SettingCompanion.insert(key: 'auto_mark_earlier', value: 'true'),
          );
      expect(await edits.readAutoMarkEarlier(), isTrue);
    });
  });

  group('episode count', () {
    // first broadcast 2026-10-05 15:00 UTC, so 5 episodes are out by _now
    const airing =
        '{"title": "T", "status": "currently_airing", "num_episodes": 12, '
        '"media_type": "tv", "start_date": "2026-10-06", '
        '"broadcast": {"day_of_the_week": "tuesday", "start_time": "00:00"}}';

    test('sets the count directly, up or down', () async {
      await addEntry('a', 'watching', watched: 3, malId: 1, json: _detail());
      expect(await edits.setEpisodes('a', 9), EditResult.done);
      expect((await readEntry('a')).episodesWatched, 9);
      expect(await edits.setEpisodes('a', 2), EditResult.done);
      expect((await readEntry('a')).episodesWatched, 2);
      expect(changes, 2);
    });

    test('reaching the total completes the title', () async {
      await addEntry('a', 'watching', watched: 3, malId: 1, json: _detail());
      await edits.setEpisodes('a', 40);
      final entry = await readEntry('a');
      expect((entry.status, entry.episodesWatched), ('completed', 12));
      expect(await readCompletions('a'), hasLength(1));
    });

    test('the same count changes nothing and tells nobody', () async {
      await addEntry('a', 'watching', watched: 3, malId: 1, json: _detail());
      expect(await edits.setEpisodes('a', 3), EditResult.done);
      expect(await edits.setEpisodes('a', -4), EditResult.done);
      expect((await readEntry('a')).episodesWatched, 0);
      expect(changes, 1);
    });

    test('only a title being watched takes a count', () async {
      await addEntry('a', 'completed', watched: 12, malId: 1, json: _detail());
      expect(await edits.setEpisodes('a', 5), EditResult.notWatching);
      expect((await readEntry('a')).episodesWatched, 12);
      expect(changes, 0);
    });

    test('an episode that has not aired is refused', () async {
      await addEntry('a', 'watching', watched: 4, malId: 1, json: airing);
      expect(await edits.setEpisodes('a', 6), EditResult.notAiredYet);
      expect((await readEntry('a')).episodesWatched, 4);
      expect(await edits.addEpisode('a'), EditResult.done);
      expect(await edits.addEpisode('a'), EditResult.notAiredYet);
      expect((await readEntry('a')).episodesWatched, 5);
      expect(changes, 1);
    });

    test('a count already past what has aired can still come down', () async {
      await addEntry('a', 'watching', watched: 9, malId: 1, json: airing);
      expect(await edits.setEpisodes('a', 7), EditResult.done);
      expect((await readEntry('a')).episodesWatched, 7);
    });
  });

  group('started date', () {
    test('the first episode sets it', () async {
      await addEntry('a', 'watching', malId: 1, json: _detail());
      await edits.addEpisode('a');
      expect((await readEntry('a')).startedAt, _now.millisecondsSinceEpoch);
    });

    test('becoming Watching sets it', () async {
      await addEntry('a', 'plan_to_watch', malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.watching);
      expect((await readEntry('a')).startedAt, _now.millisecondsSinceEpoch);
    });

    test('a date already there is kept', () async {
      await addEntry('a', 'plan_to_watch', malId: 1, json: _detail());
      await edits.setStartedDate('a', DateTime.utc(2024, 3, 1));
      await edits.setStatus('a', EntryStatus.watching);
      await edits.addEpisode('a');
      expect(
        (await readEntry('a')).startedAt,
        DateTime.utc(2024, 3, 1).millisecondsSinceEpoch,
      );
    });

    test(
      'an entry with episodes already watched did not start today',
      () async {
        await addEntry('a', 'on_hold', watched: 5, malId: 1, json: _detail());
        await edits.setStatus('a', EntryStatus.watching);
        await edits.addEpisode('a');
        expect((await readEntry('a')).startedAt, isNull);
      },
    );

    test('completing a planned title does not guess a start', () async {
      await addEntry('a', 'plan_to_watch', malId: 1, json: _detail());
      await edits.setStatus('a', EntryStatus.completed);
      expect((await readEntry('a')).startedAt, isNull);
    });

    test('is set and cleared by hand, timed with the progress', () async {
      await addEntry('a', 'watching');
      await edits.setStartedDate('a', DateTime.utc(2025, 1, 2));
      var entry = await readEntry('a');
      expect(entry.startedAt, DateTime.utc(2025, 1, 2).millisecondsSinceEpoch);
      expect(entry.progressChangedAt, _now.millisecondsSinceEpoch);
      await edits.setStartedDate('a', DateTime.utc(2025, 1, 2));
      await edits.setStartedDate('a', null);
      entry = await readEntry('a');
      expect(entry.startedAt, isNull);
      expect(changes, 2);
    });
  });

  group('notes', () {
    test('saves the text, timed on its own', () async {
      await addEntry('a', 'watching');
      await edits.setNotes('a', 'Rewatch before season 2.');
      final entry = await readEntry('a');
      expect(entry.notes, 'Rewatch before season 2.');
      expect(entry.notesChangedAt, _now.millisecondsSinceEpoch);
      expect(entry.progressChangedAt, 5);
    });

    test('empty text clears them, and the same text saves nothing', () async {
      await addEntry('a', 'watching');
      await edits.setNotes('a', '  ');
      expect(changes, 0);
      await edits.setNotes('a', 'Good');
      await edits.setNotes('a', 'Good');
      expect(changes, 1);
      await edits.setNotes('a', ' \n');
      expect((await readEntry('a')).notes, isNull);
      expect(changes, 2);
    });
  });
}
