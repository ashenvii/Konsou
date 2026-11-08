import '../data/record_database.dart';
import 'merge_records.dart';
import 'sync_record.dart';

/// The record in `konsou.db` as it goes to Drive. Merged with nothing, so its
/// rows come in the same order a merge gives and the two compare as text.
Future<SyncRecord> readLocalRecord(RecordDatabase record) async {
  Future<List<Row>> read(
    String table,
    List<String> columns, [
    String? orderBy,
  ]) async {
    final order = orderBy == null ? '' : ' ORDER BY $orderBy';
    final rows = await record
        .customSelect('SELECT ${_quote(columns).join(', ')} FROM $table$order')
        .get();
    return [for (final row in rows) orderColumns(row.data, columns)];
  }

  final references = <String, List<Row>>{};
  for (final row in await read('entry_reference', [
    'entry_id',
    ...referenceColumns,
  ], 'entry_id, provider, provider_id')) {
    (references[row['entry_id'] as String] ??= []).add(
      orderColumns(row, referenceColumns),
    );
  }
  final settings = await read('setting', settingColumns);
  final local = SyncRecord(
    entries: [
      for (final row in await read('entry', [...entryTableColumns, 'name']))
        _readFileEntry(row, references[row['entry_id']] ?? const <Row>[]),
    ],
    completions: await read('completion', completionColumns),
    alerts: await read('alert', alertColumns),
    deletions: await read('deletion', deletionColumns),
    declines: await read('match_decline', declineColumns),
    aliases: await read('entry_alias', aliasColumns),
    settings: [
      for (final row in settings)
        if (syncedSettings.contains(row['key'])) row,
    ],
  );
  return mergeRecords(local, SyncRecord());
}

Row _readFileEntry(Row row, List<Row> references) {
  final isLinked = references.any(
    (reference) => reference['provider'] == 'mal',
  );
  return orderColumns({
    ...row,
    'name': isLinked ? null : row['name'],
    'references': references,
  }, entryColumns);
}

/// Makes `konsou.db` hold [merged], in one transaction. Names already here
/// stay; an entry folded into another hands its name over when the kept one
/// has none.
Future<void> writeLocalRecord(RecordDatabase record, SyncRecord merged) {
  return record.transaction(() async {
    final localIds = {
      for (final row
          in await record.customSelect('SELECT entry_id FROM entry').get())
        row.read<String>('entry_id'),
    };
    final mergedIds = {for (final entry in merged.entries) entry['entry_id']};
    final aliases = {
      for (final row in merged.aliases) row['alias_id']: row['entry_id'],
    };
    final completionNames = {
      for (final row
          in await record
              .customSelect(
                'SELECT entry_id, watch_number, name FROM completion WHERE name IS NOT NULL',
              )
              .get())
        '${row.read<String>('entry_id')} ${row.read<int>('watch_number')}': row
            .read<String>('name'),
    };

    await record.batch((batch) {
      void insertAll(String table, List<String> columns, Iterable<Row> rows) {
        final sql =
            'INSERT INTO $table (${_quote(columns).join(', ')}) '
            'VALUES (${_placeholders(columns.length)})';
        for (final row in rows) {
          batch.customStatement(sql, [for (final c in columns) row[c]]);
        }
      }

      final columns = [...entryTableColumns, 'name'];
      final updates = [
        for (final c in entryTableColumns.skip(1)) '$c = excluded.$c',
        // a name from another device fills an empty one, never replaces one
        'name = COALESCE(entry.name, excluded.name)',
      ].join(', ');
      for (final entry in merged.entries) {
        batch.customStatement(
          'INSERT INTO entry (${columns.join(', ')}) '
          'VALUES (${_placeholders(columns.length)}) '
          'ON CONFLICT (entry_id) DO UPDATE SET $updates',
          [for (final c in columns) entry[c]],
        );
      }
      for (final id in localIds.difference(mergedIds)) {
        final keptId = aliases[id];
        if (keptId != null) {
          batch.customStatement(
            'UPDATE entry SET name = (SELECT name FROM entry WHERE entry_id = ?) '
            'WHERE entry_id = ? AND name IS NULL',
            [id, keptId],
          );
        }
        batch.customStatement('DELETE FROM entry WHERE entry_id = ?', [id]);
      }

      for (final table in [
        'entry_reference',
        'completion',
        'alert',
        'deletion',
        'match_decline',
        'entry_alias',
      ]) {
        batch.customStatement('DELETE FROM $table');
      }
      insertAll(
        'entry_reference',
        ['entry_id', ...referenceColumns],
        [
          for (final entry in merged.entries)
            for (final reference in entry['references'] as List)
              {'entry_id': entry['entry_id'], ...reference as Row},
        ],
      );
      insertAll(
        'completion',
        [...completionColumns, 'name'],
        [
          for (final row in merged.completions)
            {
              ...row,
              'name':
                  completionNames['${row['entry_id']} ${row['watch_number']}'],
            },
        ],
      );
      // a finish that arrived from another device takes its entry's name here
      batch.customStatement(
        'UPDATE completion SET name = '
        '(SELECT name FROM entry WHERE entry.entry_id = completion.entry_id) '
        'WHERE name IS NULL',
      );
      insertAll('alert', alertColumns, merged.alerts);
      insertAll('deletion', deletionColumns, merged.deletions);
      insertAll('match_decline', declineColumns, merged.declines);
      insertAll('entry_alias', aliasColumns, merged.aliases);
      for (final setting in merged.settings) {
        batch.customStatement(
          'INSERT INTO setting ("key", value, updated_at) VALUES (?, ?, ?) '
          'ON CONFLICT ("key") DO UPDATE SET value = excluded.value, '
          'updated_at = excluded.updated_at',
          [setting['key'], setting['value'], setting['updated_at']],
        );
      }
    });
  });
}

List<String> _quote(List<String> columns) => [
  for (final column in columns) column == 'key' ? '"key"' : column,
];

String _placeholders(int count) => List.filled(count, '?').join(', ');
