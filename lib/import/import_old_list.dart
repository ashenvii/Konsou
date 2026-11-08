import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import '../data/databases.dart';
import 'old_migrations.dart';

/// What an import brought over, for the first-launch screen to show.
class ImportReport {
  ImportReport({
    required this.entries,
    required this.completions,
    required this.deletions,
    required this.alerts,
    required this.scoresRounded,
    required this.timestampsFixed,
    required this.rowsSkipped,
  });

  final int entries;
  final int completions;
  final int deletions;
  final int alerts;
  final int scoresRounded;
  final int timestampsFixed;
  final int rowsSkipped;
}

/// The import did not start: the record is not empty or the file is not an
/// old Konsou list. Nothing was written.
class ImportRefused implements Exception {
  ImportRefused(this.reason);

  final String reason;

  @override
  String toString() => 'ImportRefused: $reason';
}

/// Imports the old Tauri app's database file. The file is copied first and
/// only the copy is opened, so the original is never written to.
Future<ImportReport> importOldDatabase(
  File oldFile,
  Databases databases,
) async {
  await _refuseUnlessEmpty(databases);
  final scratch = _newScratchFile();
  try {
    // copying and migrating a large list would freeze the screen on this isolate
    await Isolate.run(() => _copyAndBringUp(oldFile, scratch));
    return await _importScratch(scratch, databases);
  } finally {
    scratch.parent.deleteSync(recursive: true);
  }
}

/// Imports an old "Export list" file, a JSON array of list rows. The rows go
/// into a scratch file in the old shape and take the same path as a database.
Future<ImportReport> importExportJson(String json, Databases databases) async {
  final parsed = _decode(json);
  if (parsed is! List) throw ImportRefused('not a Konsou export');
  return _importLists(databases, entries: parsed);
}

/// Imports the old app's Drive file, `list.json`: list rows with their
/// removals and, from v0.8 on, their finished watches.
Future<ImportReport> importDriveList(String json, Databases databases) async {
  final parsed = _decode(json);
  if (parsed is! Map || parsed['entries'] is! List) {
    throw ImportRefused('not an old Konsou Drive file');
  }
  return _importLists(
    databases,
    entries: parsed['entries'] as List,
    completions: parsed['completions'] as List?,
    removals: parsed['tombstones'] as List? ?? const [],
  );
}

Object? _decode(String json) {
  try {
    return jsonDecode(json);
  } on FormatException {
    throw ImportRefused('not a Konsou export');
  }
}

Future<ImportReport> _importLists(
  Databases databases, {
  required List<dynamic> entries,
  List<dynamic>? completions,
  List<dynamic> removals = const [],
}) async {
  await _refuseUnlessEmpty(databases);
  final scratch = _newScratchFile();
  try {
    final skipped = await Isolate.run(
      () => _writeListScratch(scratch, entries, completions, removals),
    );
    return await _importScratch(scratch, databases, skippedEarlier: skipped);
  } finally {
    scratch.parent.deleteSync(recursive: true);
  }
}

File _newScratchFile() {
  final folder = Directory.systemTemp.createTempSync('konsou_import');
  return File('${folder.path}${Platform.pathSeparator}old.db');
}

void _copyAndBringUp(File oldFile, File copy) {
  oldFile.copySync(copy.path);
  // unsaved changes can sit in a side file; sqlite finishes them on the copy
  for (final side in ['-wal', '-journal']) {
    final file = File('${oldFile.path}$side');
    if (file.existsSync()) file.copySync('${copy.path}$side');
  }
  final db = sqlite3.open(copy.path);
  try {
    final ResultSet hasLog;
    try {
      hasLog = db.select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = '_sqlx_migrations'",
      );
    } on SqliteException {
      throw ImportRefused('not a database file');
    }
    if (hasLog.isEmpty) throw ImportRefused('not an old Konsou list');
    final applied = {
      for (final row in db.select(
        'SELECT version FROM _sqlx_migrations WHERE success = 1',
      ))
        row['version'] as int,
    };
    _runOldMigrations(db, (version) => !applied.contains(version));
  } finally {
    db.close();
  }
}

/// Returns how many list rows could not be written to the scratch file.
int _writeListScratch(
  File scratch,
  List<dynamic> entries,
  List<dynamic>? completions,
  List<dynamic> removals,
) {
  final db = sqlite3.open(scratch.path);
  try {
    _runOldMigrations(db, (version) => version <= 12);
    final skipped = _insertOldRows(db, 'anime_list', entries);
    if (completions == null) {
      // old migration 12 rebuilds the finished watches from the list rows
      _runOldMigrations(db, (version) => version == 12);
    } else {
      _insertOldRows(db, 'completion_log', completions);
    }
    _insertOldRows(db, 'list_tombstones', removals);
    return skipped;
  } finally {
    db.close();
  }
}

/// Writes JSON rows into an old table, keeping only the columns it has.
/// Returns how many rows it refused.
int _insertOldRows(Database db, String table, List<dynamic> rows) {
  var skipped = 0;
  final columns = {
    for (final column in db.select('PRAGMA table_info($table)'))
      column['name'] as String,
  }..remove('id');
  for (final row in rows) {
    if (row is! Map<String, dynamic>) {
      skipped++;
      continue;
    }
    final values = {
      for (final MapEntry(:key, :value) in row.entries)
        if (columns.contains(key) && value is! Map && value is! List)
          key: value is bool ? (value ? 1 : 0) : value,
    };
    try {
      db.execute(
        'INSERT INTO $table (${values.keys.join(', ')}) '
        'VALUES (${List.filled(values.length, '?').join(', ')})',
        values.values.toList(),
      );
    } on SqliteException {
      skipped++;
    }
  }
  return skipped;
}

void _runOldMigrations(Database db, bool Function(int version) include) {
  for (final MapEntry(key: version, value: sql) in oldMigrations.entries) {
    if (include(version)) db.execute(sql);
  }
}

Future<void> _refuseUnlessEmpty(Databases databases) async {
  final row = await databases.record.customSelect('''
    SELECT (SELECT count(*) FROM entry) + (SELECT count(*) FROM completion)
      + (SELECT count(*) FROM deletion) + (SELECT count(*) FROM alert) AS rows
  ''').getSingle();
  if (row.read<int>('rows') > 0) {
    throw ImportRefused('the list already has entries');
  }
}

Future<ImportReport> _importScratch(
  File scratchFile,
  Databases databases, {
  int skippedEarlier = 0,
}) async {
  final record = databases.record;
  await record.customStatement('ATTACH DATABASE ? AS old', [scratchFile.path]);
  try {
    final languageRows = await record
        .customSelect(
          "SELECT value FROM old.settings WHERE key = 'title_language'",
        )
        .get();
    final language = languageRows.isEmpty
        ? null
        : languageRows.single.read<String>('value');

    return await record.transaction(() async {
      for (final statement in _importStatements(language)) {
        await record.customStatement(statement);
      }
      final counts = await record.customSelect(_countsAfterImport).getSingle();
      final entries = counts.read<int>('entries');
      return ImportReport(
        entries: entries,
        completions: counts.read<int>('completions'),
        deletions: counts.read<int>('deletions'),
        alerts: counts.read<int>('alerts'),
        scoresRounded: counts.read<int>('scores_rounded'),
        timestampsFixed: counts.read<int>('timestamps_fixed'),
        rowsSkipped: skippedEarlier + counts.read<int>('old_entries') - entries,
      );
    });
  } finally {
    await record.customStatement('DETACH DATABASE old');
  }
}

/// An old airing-scan bug wrote seconds where milliseconds belong. Anything
/// this small would be a date before 1973 in milliseconds.
const _secondsBelow = 100000000000;

String _milliseconds(String column) =>
    'CASE WHEN $column < $_secondsBelow THEN $column * 1000 ELSE $column END';

/// Old rows that became entries, joined to the entry they became.
const _imported =
    "entry JOIN old.anime_list ON entry_id = 'legacy-' || anime_list.anilist_id";

const _countsAfterImport =
    '''
  SELECT (SELECT count(*) FROM entry) AS entries,
         (SELECT count(*) FROM completion) AS completions,
         (SELECT count(*) FROM deletion) AS deletions,
         (SELECT count(*) FROM alert) AS alerts,
         (SELECT count(*) FROM old.anime_list) AS old_entries,
         (SELECT count(*) FROM $_imported
           WHERE anime_list.score <> ROUND(anime_list.score)) AS scores_rounded,
         (SELECT count(*) FROM $_imported
           WHERE anime_list.added_at < $_secondsBelow
              OR anime_list.updated_at < $_secondsBelow
              OR anime_list.started_at < $_secondsBelow)
         + (SELECT count(*) FROM old.completion_log WHERE completed_at < $_secondsBelow)
         + (SELECT count(*) FROM old.notifications WHERE created_at < $_secondsBelow)
         + (SELECT count(*) FROM old.list_tombstones WHERE deleted_at < $_secondsBelow)
           AS timestamps_fixed
''';

/// The title the user's language setting picks, falling back to the others.
String _pickName(String? language, String table) {
  final romaji = '$table.title_romaji';
  final english = "NULLIF($table.title_english, '')";
  final native = "NULLIF($table.title_native, '')";
  return switch (language) {
    'english' => 'COALESCE($english, $romaji, $native)',
    'native' => 'COALESCE($native, $romaji, $english)',
    _ => 'COALESCE($romaji, $english, $native)',
  };
}

List<String> _importStatements(String? language) => [
  // old dev builds dropped the status check; rows the new schema refuses are
  // skipped here and counted in the report
  '''
  INSERT OR IGNORE INTO entry (entry_id, name, status, episodes_watched, score,
                               notes, plan_rank, added_at, started_at,
                               progress_changed_at, score_changed_at,
                               notes_changed_at, link_changed_at)
  SELECT 'legacy-' || anilist_id, ${_pickName(language, 'anime_list')}, status,
         episodes_watched, CAST(ROUND(score) AS INTEGER), notes, plan_rank,
         ${_milliseconds('added_at')}, ${_milliseconds('started_at')},
         changed_at, changed_at, changed_at, changed_at
  FROM (SELECT *, ${_milliseconds('updated_at')} AS changed_at FROM old.anime_list)
       AS anime_list
  ''',
  '''
  INSERT INTO entry_reference (entry_id, provider, provider_id)
  SELECT entry_id, 'anilist', anilist_id FROM $_imported
  ''',
  '''
  INSERT INTO entry_reference (entry_id, provider, provider_id)
  SELECT entry_id, 'mal', mal_id FROM $_imported WHERE mal_id IS NOT NULL
  ''',
  '''
  INSERT INTO completion (entry_id, watch_number, completed_at, episodes_watched,
                          minutes_per_episode, is_estimated, name)
  SELECT 'legacy-' || completion_log.anilist_id, rewatch_index,
         ${_milliseconds('completed_at')}, episodes_at_completion,
         episode_duration, estimated,
         COALESCE(entry.name, ${_pickName(language, 'completion_log')})
  FROM old.completion_log
  LEFT JOIN entry ON entry.entry_id = 'legacy-' || completion_log.anilist_id
  ''',
  '''
  INSERT INTO alert (entry_id, related_provider, related_provider_id, type,
                     seen, dismissed, created_at)
  SELECT 'legacy-' || source_id, 'anilist', related_id, type, seen, dismissed,
         ${_milliseconds('created_at')}
  FROM old.notifications
  ''',
  '''
  INSERT INTO deletion (entry_id, deleted_at)
  SELECT 'legacy-' || anilist_id, ${_milliseconds('deleted_at')}
  FROM old.list_tombstones
  ''',
  '''
  INSERT INTO setting ("key", value)
  SELECT "key", value FROM old.settings WHERE "key" = 'title_language'
  ''',
  // details.db is a cache, so a leftover row from an earlier try is replaced
  '''
  INSERT OR REPLACE INTO details.franchise_link
    (entry_id, franchise_provider, franchise_provider_id, is_placeholder)
  SELECT entry_id, 'anilist', franchise_root_id, 1 FROM $_imported
  WHERE franchise_root_id IS NOT NULL
  ''',
];
