import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/sync/merge_records.dart';
import 'package:konsou/sync/sync_record.dart';

import '../support/sync_rows.dart';

Row findEntry(SyncRecord record, String id) =>
    record.entries.singleWhere((entry) => entry['entry_id'] == id);

/// Merges both ways and checks the two answers are the same text.
SyncRecord mergeBothWays(SyncRecord a, SyncRecord b) {
  final ab = mergeRecords(a, b);
  expect(mergeRecords(b, a).toJson(), ab.toJson(), reason: 'order matters');
  expect(mergeRecords(ab, ab).toJson(), ab.toJson(), reason: 'not stable');
  expect(
    mergeRecords(ab, a).toJson(),
    ab.toJson(),
    reason: 'a again changed it',
  );
  expect(
    mergeRecords(ab, b).toJson(),
    ab.toJson(),
    reason: 'b again changed it',
  );
  return ab;
}

void main() {
  test('entries on one side only come through', () {
    final merged = mergeBothWays(
      SyncRecord(entries: [buildEntry('a')]),
      SyncRecord(entries: [buildEntry('b')]),
    );
    expect(merged.entries.map((entry) => entry['entry_id']), ['a', 'b']);
  });

  test('each group takes the side that changed it last', () {
    final pc = buildEntry(
      'x',
      episodes: 3,
      progressAt: 10,
      notes: 'pc note',
      notesAt: 50,
    );
    final phone = buildEntry(
      'x',
      episodes: 7,
      progressAt: 40,
      notes: 'old',
      notesAt: 20,
    );
    final merged = findEntry(
      mergeBothWays(SyncRecord(entries: [pc]), SyncRecord(entries: [phone])),
      'x',
    );
    expect(merged['episodes_watched'], 7);
    expect(merged['progress_changed_at'], 40);
    expect(merged['notes'], 'pc note');
    expect(merged['notes_changed_at'], 50);
  });

  test('a rewatch reset to 0 is not undone by a higher old count', () {
    final rewatch = buildEntry(
      'x',
      status: 'rewatching',
      episodes: 0,
      progressAt: 90,
    );
    final old = buildEntry(
      'x',
      status: 'completed',
      episodes: 24,
      progressAt: 30,
    );
    final merged = findEntry(
      mergeBothWays(SyncRecord(entries: [rewatch]), SyncRecord(entries: [old])),
      'x',
    );
    expect(merged['status'], 'rewatching');
    expect(merged['episodes_watched'], 0);
  });

  test('a tie in change time gives the same answer on both devices', () {
    final merged = mergeBothWays(
      SyncRecord(entries: [buildEntry('x', score: 6, scoreAt: 70)]),
      SyncRecord(entries: [buildEntry('x', score: 9, scoreAt: 70)]),
    );
    expect(findEntry(merged, 'x')['score_changed_at'], 70);
  });

  test('a not-linked name comes along until the entry is linked', () {
    final unlinked = buildEntry(
      'x',
      name: 'Scott Pilgrim Takes Off',
      linkAt: 1,
    );
    expect(
      findEntry(
        mergeBothWays(SyncRecord(entries: [unlinked]), SyncRecord()),
        'x',
      )['name'],
      'Scott Pilgrim Takes Off',
    );

    final linkedLater = buildEntry('x', malId: 99, linkAt: 50);
    final merged = findEntry(
      mergeBothWays(
        SyncRecord(entries: [unlinked]),
        SyncRecord(entries: [linkedLater]),
      ),
      'x',
    );
    expect(merged['name'], isNull);
    expect(merged['references'], [
      {'provider': 'mal', 'provider_id': 99},
    ]);
  });

  test('the earlier added time is kept', () {
    final merged = mergeBothWays(
      SyncRecord(entries: [buildEntry('x', addedAt: 100)]),
      SyncRecord(entries: [buildEntry('x', addedAt: 40)]),
    );
    expect(findEntry(merged, 'x')['added_at'], 40);
  });

  test('a removal is final, even against a later edit', () {
    final merged = mergeBothWays(
      SyncRecord(
        deletions: [
          {'entry_id': 'x', 'deleted_at': 10},
        ],
      ),
      SyncRecord(entries: [buildEntry('x', episodes: 5, progressAt: 99)]),
    );
    expect(merged.entries, isEmpty);
    expect(merged.deletions.single['entry_id'], 'x');
  });

  test('the same title added on two devices becomes one entry', () {
    final pc = buildEntry(
      'pc',
      addedAt: 100,
      malId: 52991,
      notes: 'mine',
      notesAt: 120,
    );
    final phone = buildEntry(
      'phone',
      addedAt: 50,
      malId: 52991,
      episodes: 4,
      progressAt: 60,
    );
    final merged = mergeBothWays(
      SyncRecord(entries: [pc], completions: [buildCompletion('pc', 0, 200)]),
      SyncRecord(entries: [phone]),
    );
    final kept = merged.entries.single;
    expect(kept['entry_id'], 'phone');
    expect(kept['notes'], 'mine');
    expect(kept['episodes_watched'], 4);
    expect(merged.aliases.single, {'alias_id': 'pc', 'entry_id': 'phone'});
    expect(merged.completions.single['entry_id'], 'phone');
  });

  test('an alias from Drive folds a device that still has the old id', () {
    final drive = mergeRecords(
      SyncRecord(entries: [buildEntry('pc', addedAt: 100, malId: 1)]),
      SyncRecord(entries: [buildEntry('phone', addedAt: 50, malId: 1)]),
    );
    final pcAgain = SyncRecord(
      entries: [
        buildEntry('pc', addedAt: 100, malId: 1, score: 8, scoreAt: 300),
      ],
    );
    final merged = mergeBothWays(pcAgain, drive);
    expect(merged.entries.single['entry_id'], 'phone');
    expect(merged.entries.single['score'], 8);
  });

  test('two titles that share one page on both sides are not duplicates', () {
    final both = SyncRecord(
      entries: [
        buildEntry('legacy-106169', status: 'plan_to_watch', malId: 38431),
        buildEntry('legacy-106896', status: 'completed', malId: 38431),
      ],
    );
    final merged = mergeBothWays(both, both);
    expect(merged.entries, hasLength(2));
    expect(merged.aliases, isEmpty);
  });

  test(
    'a new entry is not folded into a pair that already shares its page',
    () {
      final merged = mergeBothWays(
        SyncRecord(
          entries: [
            buildEntry('legacy-1', malId: 9),
            buildEntry('legacy-2', malId: 9),
          ],
        ),
        SyncRecord(entries: [buildEntry('new', malId: 9)]),
      );
      expect(merged.entries, hasLength(3));
    },
  );

  test('an entry that would fold two different entries folds neither', () {
    final both = orderColumns({
      ...buildEntry('old', addedAt: 5),
      'references': [
        {'provider': 'anilist', 'provider_id': 9},
        {'provider': 'mal', 'provider_id': 1},
      ],
    }, entryColumns);
    final anilistOnly = orderColumns({
      ...buildEntry('a-new'),
      'references': [
        {'provider': 'anilist', 'provider_id': 9},
      ],
    }, entryColumns);
    final merged = mergeBothWays(
      SyncRecord(entries: [both]),
      SyncRecord(entries: [buildEntry('m-new', malId: 1), anilistOnly]),
    );
    expect(merged.entries, hasLength(3));
    expect(merged.aliases, isEmpty);
  });

  test(
    'a recorded finish beats an estimated one, else the earlier date wins',
    () {
      final merged = mergeBothWays(
        SyncRecord(
          entries: [buildEntry('x')],
          completions: [
            buildCompletion('x', 0, 100, estimated: true),
            buildCompletion('x', 1, 900),
          ],
        ),
        SyncRecord(
          entries: [buildEntry('x')],
          completions: [
            buildCompletion('x', 0, 500),
            buildCompletion('x', 1, 700),
          ],
        ),
      );
      expect(merged.completions.map((row) => row['completed_at']), [500, 700]);
    },
  );

  test('seen and dismissed only turn on', () {
    final merged = mergeBothWays(
      SyncRecord(
        entries: [buildEntry('x')],
        alerts: [buildAlert('x', 2, seen: 1)],
      ),
      SyncRecord(
        entries: [buildEntry('x')],
        alerts: [buildAlert('x', 2, dismissed: 1)],
      ),
    );
    expect(merged.alerts.single['seen'], 1);
    expect(merged.alerts.single['dismissed'], 1);
  });

  test('declines union and drop when their entry is removed', () {
    Row decline(String id, int page) => {
      'entry_id': id,
      'provider': 'mal',
      'provider_id': page,
      'declined_at': 3,
    };
    final merged = mergeBothWays(
      SyncRecord(entries: [buildEntry('x')], declines: [decline('x', 1)]),
      SyncRecord(
        entries: [buildEntry('x')],
        declines: [decline('x', 2), decline('gone', 3)],
        deletions: [
          {'entry_id': 'gone', 'deleted_at': 4},
        ],
      ),
    );
    expect(merged.declines.map((row) => row['provider_id']), [1, 2]);
  });

  test('finished watches and alerts drop with their removed entry', () {
    final merged = mergeBothWays(
      SyncRecord(
        entries: [buildEntry('x'), buildEntry('gone')],
        completions: [
          buildCompletion('x', 0, 5),
          buildCompletion('gone', 0, 5),
        ],
        alerts: [buildAlert('x', 1), buildAlert('gone', 2)],
      ),
      SyncRecord(
        entries: [buildEntry('x')],
        completions: [buildCompletion('gone', 1, 6)],
        deletions: [
          {'entry_id': 'gone', 'deleted_at': 4},
        ],
      ),
    );
    expect(merged.completions.map((row) => row['entry_id']), ['x']);
    expect(merged.alerts.map((row) => row['entry_id']), ['x']);
  });

  test('a setting takes the side that changed it last', () {
    final merged = mergeBothWays(
      SyncRecord(
        settings: [
          {'key': 'title_language', 'value': 'english', 'updated_at': 20},
        ],
      ),
      SyncRecord(
        settings: [
          {'key': 'title_language', 'value': 'romaji', 'updated_at': 10},
        ],
      ),
    );
    expect(merged.settings.single['value'], 'english');
  });

  test('a file from a newer Konsou is refused', () {
    expect(
      () => SyncRecord.fromJson('{"format": 2, "entries": []}'),
      throwsA(isA<NewerFormat>()),
    );
  });

  test('the file reads back to the same record', () {
    final record = SyncRecord(
      entries: [buildEntry('x', malId: 4, notes: 'n', notesAt: 3)],
      completions: [buildCompletion('x', 0, 9)],
      alerts: [buildAlert('x', 5)],
    );
    expect(SyncRecord.fromJson(record.toJson()).toJson(), record.toJson());
  });
}
