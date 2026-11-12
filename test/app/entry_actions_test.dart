import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/entry_actions.dart';
import 'package:konsou/app/toast_host.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/library/entry_edits.dart';
import 'package:konsou/library/entry_status.dart';

void main() {
  late Directory folder;
  late Databases databases;
  late EntryEdits edits;
  late EntryActions actions;
  late List<ToastMessage> shown;
  late int dismissed;
  late int edited;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_entry_actions');
    databases = await openDatabases(folder);
    edits = EntryEdits(databases: databases);
    shown = [];
    dismissed = 0;
    edited = 0;
    actions = EntryActions(
      databases: databases,
      edits: edits,
      show: shown.add,
      dismiss: () => dismissed++,
      onEdited: () => edited++,
    );
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addTitle(
    int malId,
    String start, {
    String airing = 'finished_airing',
    List<(int, String)> relations = const [],
    String? entryId,
    String status = 'plan_to_watch',
    int watched = 0,
  }) async {
    final json = jsonEncode({
      'title': 'Title $malId',
      'media_type': 'tv',
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
            episodesWatched: Value(watched),
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

  // S1 (1) and S2 (2) in a chain; S2 is on the list at 11 of 12 episodes
  Future<void> addPair({
    String s1Status = 'plan_to_watch',
    bool s1OnList = true,
  }) async {
    await addTitle(
      1,
      '2019-01-01',
      relations: [(2, 'sequel')],
      entryId: s1OnList ? 'e1' : null,
      status: s1Status,
    );
    await addTitle(
      2,
      '2020-01-01',
      relations: [(1, 'prequel')],
      entryId: 'e2',
      status: 'watching',
      watched: 11,
    );
  }

  Future<Entry> readEntry(String id) {
    final record = databases.record;
    return (record.select(
      record.entry,
    )..where((row) => row.entryId.equals(id))).getSingle();
  }

  test('a mark shows "Marked as X" with Undo, and Undo puts it back', () async {
    await addTitle(5, '2020-01-01', entryId: 'e5');
    final result = await actions.setStatus('e5', EntryStatus.onHold);
    expect(result, EditResult.done);
    expect(shown.single.text, 'Marked as On hold');
    expect(shown.single.undo, isNotNull);
    await shown.single.undo!();
    expect((await readEntry('e5')).status, 'plan_to_watch');
  });

  test('screens are told after an edit and again after its Undo', () async {
    await addTitle(5, '2020-01-01', entryId: 'e5');
    await actions.setStatus('e5', EntryStatus.onHold);
    final afterEdit = edited;
    expect(afterEdit, greaterThan(0));
    await shown.single.undo!();
    expect(edited, greaterThan(afterEdit));
  });

  test('a locked status shows the reason and changes nothing', () async {
    await addTitle(5, '2030-01-01', airing: 'not_yet_aired', entryId: 'e5');
    final result = await actions.setStatus('e5', EntryStatus.completed);
    expect(result, EditResult.notAiredYet);
    expect(shown.single.text, contains('not aired'));
    expect(shown.single.undo, isNull);
    expect((await readEntry('e5')).status, 'plan_to_watch');
  });

  test('an episode shows its number, with Undo', () async {
    await addTitle(5, '2020-01-01', entryId: 'e5', status: 'watching');
    await actions.addEpisode('e5');
    expect(shown.single.text, 'Episode 1');
    await shown.single.undo!();
    expect((await readEntry('e5')).episodesWatched, 0);
  });

  test('an episode on a title that is not being watched says why', () async {
    await addTitle(5, '2020-01-01', entryId: 'e5');
    await actions.addEpisode('e5');
    expect(shown.single.text, contains('Watching'));
    expect(shown.single.undo, isNull);
  });

  test('an episode at the total shows nothing', () async {
    await addTitle(
      5,
      '2020-01-01',
      entryId: 'e5',
      status: 'watching',
      watched: 12,
    );
    await actions.addEpisode('e5');
    expect(shown, isEmpty);
  });

  test('finishing with nothing earlier shows only the mark', () async {
    await addTitle(5, '2020-01-01', entryId: 'e5', status: 'watching');
    await actions.setStatus('e5', EntryStatus.completed);
    expect(shown.single.text, 'Marked as Completed');
    expect(shown.single.review, isNull);
  });

  test('finishing a later season offers the review', () async {
    await addPair();
    await actions.setStatus('e2', EntryStatus.completed);
    final toast = shown.single;
    expect(toast.review, isNotNull);
    expect(toast.review!.entryId, 'e2');
    expect(toast.review!.titles.map((title) => title.malId), [1]);
    expect(toast.text, contains('1 earlier title'));
    expect(toast.text, contains('Title 2'));
  });

  test('finishing the last episode offers the review too', () async {
    await addPair();
    await actions.addEpisode('e2');
    expect(shown.single.review, isNotNull);
  });

  test('Undo on the review toast takes the finish back', () async {
    await addPair();
    await actions.setStatus('e2', EntryStatus.completed);
    await shown.single.undo!();
    final entry = await readEntry('e2');
    expect(entry.status, 'watching');
    expect(entry.episodesWatched, 11);
  });

  test('no review when the title was already completed', () async {
    await addPair();
    await actions.setStatus('e2', EntryStatus.completed);
    shown.clear();
    await actions.setStatus('e2', EntryStatus.completed);
    expect(shown, isEmpty);
  });

  group('with auto-mark on', () {
    setUp(() async {
      final record = databases.record;
      await record
          .into(record.setting)
          .insert(
            SettingCompanion.insert(
              key: autoMarkEarlierKey,
              value: 'true',
              updatedAt: const Value(1),
            ),
          );
    });

    test('marks the earlier titles and says so, with Undo for all', () async {
      await addPair();
      await actions.setStatus('e2', EntryStatus.completed);
      expect(shown.single.text, 'Also marked 1 earlier title');
      expect(shown.single.review, isNull);
      expect((await readEntry('e1')).status, 'completed');
      await shown.single.undo!();
      expect((await readEntry('e1')).status, 'plan_to_watch');
      expect((await readEntry('e2')).status, 'watching');
    });

    test('adds an earlier title that is not on the list', () async {
      await addPair(s1OnList: false);
      await actions.setStatus('e2', EntryStatus.completed);
      final record = databases.record;
      final rows = await record.select(record.entry).get();
      expect(rows.length, 2);
      await shown.single.undo!();
      expect((await record.select(record.entry).get()).length, 1);
    });
  });

  group('the review', () {
    test(
      'marking closes the review toast and shows a toast with Undo',
      () async {
        await addPair();
        await actions.setStatus('e2', EntryStatus.completed);
        final offer = shown.single.review!;
        shown.clear();
        await actions.acceptReview(offer.titles);
        expect(dismissed, 1);
        expect(shown.single.text, 'Marked 1 earlier title completed');
        expect((await readEntry('e1')).status, 'completed');
        await shown.single.undo!();
        expect((await readEntry('e1')).status, 'plan_to_watch');
      },
    );

    test('Not now saves the reminder and says where it went', () async {
      await addPair();
      await actions.setStatus('e2', EntryStatus.completed);
      final offer = shown.single.review!;
      shown.clear();
      await actions.notNow(offer);
      expect(dismissed, 1);
      expect(shown.single.text, contains('bell'));
      final record = databases.record;
      final alerts = await record.select(record.alert).get();
      expect(alerts.single.type, 'earlier_unmarked');
      expect(alerts.single.entryId, 'e2');
    });

    test('a rating is saved on the finished title', () async {
      await addPair();
      await actions.rate('e2', 8);
      expect((await readEntry('e2')).score, 8);
    });
  });
}
