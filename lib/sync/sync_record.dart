import 'dart:convert';

typedef Row = Map<String, Object?>;

/// The format number written into `record.json`. A file with a higher one
/// came from a newer Konsou and is never overwritten.
const recordFormat = 1;

/// Settings that follow the user to every device. Everything else stays local.
const syncedSettings = {'title_language'};

/// Each group of an entry's fields and the column that times its last change.
const entryGroups = {
  'progress_changed_at': [
    'status',
    'episodes_watched',
    'started_at',
    'plan_rank',
  ],
  'score_changed_at': ['score'],
  'notes_changed_at': ['notes'],
  // a not-linked entry's name travels with its references, see entryColumns
  'link_changed_at': ['references', 'name'],
};

/// The entry columns kept in `konsou.db`'s entry table.
const entryTableColumns = [
  'entry_id',
  'status',
  'episodes_watched',
  'score',
  'notes',
  'plan_rank',
  'added_at',
  'started_at',
  'progress_changed_at',
  'score_changed_at',
  'notes_changed_at',
  'link_changed_at',
];

/// An entry in the file also carries its provider references, and its name
/// while it has no MAL page (a name from MAL never goes to Drive).
const entryColumns = [...entryTableColumns, 'name', 'references'];
const referenceColumns = ['provider', 'provider_id'];
const completionColumns = [
  'entry_id',
  'watch_number',
  'completed_at',
  'episodes_watched',
  'minutes_per_episode',
  'is_estimated',
];
const alertColumns = [
  'entry_id',
  'related_provider',
  'related_provider_id',
  'type',
  'seen',
  'dismissed',
  'created_at',
];
const deletionColumns = ['entry_id', 'deleted_at'];
const declineColumns = ['entry_id', 'provider', 'provider_id', 'declined_at'];
const aliasColumns = ['alias_id', 'entry_id'];
const settingColumns = ['key', 'value', 'updated_at'];

/// `record.json` came from a newer Konsou, so this one cannot read it.
class NewerFormat implements Exception {
  NewerFormat(this.format);

  final int format;

  @override
  String toString() => 'NewerFormat: $format';
}

/// The whole record without names: what sync reads, merges and uploads.
class SyncRecord {
  SyncRecord({
    this.entries = const [],
    this.completions = const [],
    this.alerts = const [],
    this.deletions = const [],
    this.declines = const [],
    this.aliases = const [],
    this.settings = const [],
  });

  /// Throws [NewerFormat] for a file from a newer Konsou and
  /// [FormatException] for one that is damaged.
  factory SyncRecord.fromJson(String json) {
    try {
      return SyncRecord._read(jsonDecode(json) as Map<String, dynamic>);
    } on TypeError {
      throw const FormatException('record.json is damaged');
    }
  }

  factory SyncRecord._read(Map<String, dynamic> file) {
    final format = file['format'] as int;
    if (format > recordFormat) throw NewerFormat(format);
    List<Row> read(String table, List<String> columns) => [
      for (final row in file[table] as List? ?? const [])
        orderColumns(row as Map<String, dynamic>, columns),
    ];
    return SyncRecord(
      entries: [
        for (final row in read('entries', entryColumns))
          {
            ...row,
            'references': [
              for (final reference in row['references'] as List? ?? const [])
                orderColumns(
                  reference as Map<String, dynamic>,
                  referenceColumns,
                ),
            ],
          },
      ],
      completions: read('completions', completionColumns),
      alerts: read('alerts', alertColumns),
      deletions: read('deletions', deletionColumns),
      declines: read('declines', declineColumns),
      aliases: read('aliases', aliasColumns),
      settings: read('settings', settingColumns),
    );
  }

  final List<Row> entries;
  final List<Row> completions;
  final List<Row> alerts;
  final List<Row> deletions;
  final List<Row> declines;
  final List<Row> aliases;
  final List<Row> settings;

  /// The file's text. Rows and columns come in a fixed order, so the same
  /// record always gives the same text and two records compare as text.
  String toJson() => jsonEncode({
    'format': recordFormat,
    'entries': entries,
    'completions': completions,
    'alerts': alerts,
    'deletions': deletions,
    'declines': declines,
    'aliases': aliases,
    'settings': settings,
  });

  /// The latest change time anywhere in the record.
  int get newestTime {
    var newest = 0;
    void take(Iterable<Row> rows, List<String> columns) {
      for (final row in rows) {
        for (final column in columns) {
          final time = row[column] as int? ?? 0;
          if (time > newest) newest = time;
        }
      }
    }

    take(entries, entryGroups.keys.toList());
    take(completions, const ['completed_at']);
    take(alerts, const ['created_at']);
    take(deletions, const ['deleted_at']);
    take(declines, const ['declined_at']);
    take(settings, const ['updated_at']);
    return newest;
  }
}

Row orderColumns(Map<String, Object?> row, List<String> columns) => {
  for (final column in columns) column: row[column],
};
