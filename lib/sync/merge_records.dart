import 'dart:convert';
import 'dart:math';

import 'sync_record.dart';

/// Merges two records into the one every device ends up with. The answer is
/// the same whichever side is passed first, and merging it again with either
/// side changes nothing.
SyncRecord mergeRecords(SyncRecord a, SyncRecord b) {
  final aliases = <String, String>{
    for (final row in _unionRows(
      [...a.aliases, ...b.aliases],
      (row) => row['alias_id'] as String,
      _pickByText,
    ))
      row['alias_id'] as String: row['entry_id'] as String,
  };
  String resolve(String id) {
    final seen = <String>{};
    while (aliases.containsKey(id) && seen.add(id)) {
      id = aliases[id]!;
    }
    return id;
  }

  aliases.addAll(_findDuplicates(a, b, resolve));
  Row rekey(Row row) => {
    ...row,
    'entry_id': resolve(row['entry_id'] as String),
  };

  final deletions = _unionRows(
    [...a.deletions, ...b.deletions].map(rekey),
    (row) => row['entry_id'] as String,
    (x, y) => _pickSmaller(x, y, 'deleted_at'),
  );
  final removed = {for (final row in deletions) row['entry_id']};
  final entries = _unionRows(
    [...a.entries, ...b.entries].map(rekey),
    (row) => row['entry_id'] as String,
    _mergeEntry,
  ).where((entry) => !removed.contains(entry['entry_id'])).toList();
  final alive = {for (final entry in entries) entry['entry_id']};

  return SyncRecord(
    entries: entries,
    completions: _unionRows(
      [
        ...a.completions,
        ...b.completions,
      ].map(rekey).where((row) => alive.contains(row['entry_id'])),
      (row) => '${row['entry_id']} ${row['watch_number']}',
      _mergeCompletion,
    ),
    alerts: _unionRows(
      [
        ...a.alerts,
        ...b.alerts,
      ].map(rekey).where((row) => alive.contains(row['entry_id'])),
      (row) => jsonEncode([
        row['entry_id'],
        row['related_provider'],
        row['related_provider_id'],
        row['type'],
      ]),
      _mergeAlert,
    ),
    deletions: deletions,
    declines: _unionRows(
      [
        ...a.declines,
        ...b.declines,
      ].map(rekey).where((row) => alive.contains(row['entry_id'])),
      (row) => '${row['entry_id']} ${row['provider']} ${row['provider_id']}',
      (x, y) => _pickSmaller(x, y, 'declined_at'),
    ),
    aliases: [
      for (final MapEntry(:key, :value)
          in (aliases.entries.toList()..sort((x, y) => x.key.compareTo(y.key))))
        {'alias_id': key, 'entry_id': resolve(value)},
    ],
    settings: _unionRows(
      [...a.settings, ...b.settings],
      (row) => row['key'] as String,
      (x, y) => _pickLater(x, y, 'updated_at'),
    ),
  );
}

/// Pairs of entries for one provider page where each entry is on one side
/// only: the same title added on two devices before they synced. The newer
/// one becomes an alias of the older. A page shared by more than one entry
/// on a side is left alone, since those are different titles on purpose.
Map<String, String> _findDuplicates(
  SyncRecord a,
  SyncRecord b,
  String Function(String id) resolve,
) {
  Set<String> knownIds(SyncRecord side) => {
    for (final row in side.entries) resolve(row['entry_id'] as String),
    for (final row in side.deletions) resolve(row['entry_id'] as String),
    for (final row in side.aliases) row['alias_id'] as String,
  };
  Map<String, List<Row>> onlyHere(SyncRecord side, Set<String> otherIds) {
    final byPage = <String, List<Row>>{};
    for (final entry in side.entries) {
      if (otherIds.contains(resolve(entry['entry_id'] as String))) continue;
      for (final reference in entry['references'] as List) {
        final page = jsonEncode(reference);
        (byPage[page] ??= []).add(entry);
      }
    }
    return byPage;
  }

  final fromA = onlyHere(a, knownIds(b));
  final fromB = onlyHere(b, knownIds(a));
  final pairs = <(Row, Row)>{};
  for (final MapEntry(key: page, value: hereA) in fromA.entries) {
    final hereB = fromB[page];
    if (hereA.length != 1 || hereB == null || hereB.length != 1) continue;
    pairs.add((hereA.single, hereB.single));
  }
  // an entry that would pair with two different entries is left alone, so the
  // answer never depends on which pair is looked at first
  final partners = <Object?, Set<Object?>>{};
  for (final (x, y) in pairs) {
    (partners[x['entry_id']] ??= {}).add(y['entry_id']);
    (partners[y['entry_id']] ??= {}).add(x['entry_id']);
  }
  final found = <String, String>{};
  for (final (x, y) in pairs) {
    if (partners[x['entry_id']]!.length > 1) continue;
    if (partners[y['entry_id']]!.length > 1) continue;
    final (kept, folded) = _isOlder(x, y) ? (x, y) : (y, x);
    found[resolve(folded['entry_id'] as String)] = resolve(
      kept['entry_id'] as String,
    );
  }
  return found;
}

bool _isOlder(Row x, Row y) {
  final byAdded = (x['added_at'] as int).compareTo(y['added_at'] as int);
  if (byAdded != 0) return byAdded < 0;
  return (x['entry_id'] as String).compareTo(y['entry_id'] as String) < 0;
}

Row _mergeEntry(Row x, Row y) {
  final merged = {
    ...x,
    'added_at': min(x['added_at'] as int, y['added_at'] as int),
  };
  for (final MapEntry(key: timeColumn, value: columns) in entryGroups.entries) {
    final xTime = x[timeColumn] as int;
    final yTime = y[timeColumn] as int;
    final Row winner;
    if (xTime != yTime) {
      winner = xTime > yTime ? x : y;
    } else {
      String groupText(Row row) =>
          jsonEncode([for (final c in columns) row[c]]);
      winner = groupText(x).compareTo(groupText(y)) >= 0 ? x : y;
    }
    merged[timeColumn] = winner[timeColumn];
    for (final column in columns) {
      merged[column] = winner[column];
    }
  }
  return orderColumns(merged, entryColumns);
}

/// A recorded date beats an estimated one; otherwise the earlier date, since
/// a device that learns about a finish later is echoing it.
Row _mergeCompletion(Row x, Row y) {
  if (x['is_estimated'] != y['is_estimated']) {
    return x['is_estimated'] == 0 ? x : y;
  }
  return _pickSmaller(x, y, 'completed_at');
}

Row _mergeAlert(Row x, Row y) => {
  ...x,
  'seen': max(x['seen'] as int, y['seen'] as int),
  'dismissed': max(x['dismissed'] as int, y['dismissed'] as int),
  'created_at': min(x['created_at'] as int, y['created_at'] as int),
};

Row _pickSmaller(Row x, Row y, String column) {
  final order = (x[column] as int).compareTo(y[column] as int);
  if (order == 0) return _pickByText(x, y);
  return order < 0 ? x : y;
}

Row _pickLater(Row x, Row y, String column) {
  final order = (x[column] as int).compareTo(y[column] as int);
  if (order == 0) return _pickByText(x, y);
  return order > 0 ? x : y;
}

/// The last tie-break: both devices compare the same text, so both pick the
/// same row.
Row _pickByText(Row x, Row y) =>
    jsonEncode(x).compareTo(jsonEncode(y)) >= 0 ? x : y;

/// One row per key, rows with the same key combined, sorted by key.
List<Row> _unionRows(
  Iterable<Row> rows,
  String Function(Row row) keyOf,
  Row Function(Row x, Row y) combine,
) {
  final byKey = <String, Row>{};
  for (final row in rows) {
    final key = keyOf(row);
    final held = byKey[key];
    byKey[key] = held == null ? row : combine(held, row);
  }
  final keys = byKey.keys.toList()..sort();
  return [for (final key in keys) byKey[key]!];
}
