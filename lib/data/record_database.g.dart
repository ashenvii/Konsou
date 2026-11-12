// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_database.dart';

// ignore_for_file: type=lint
class EntryTable extends Table with TableInfo<EntryTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EntryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'watching\', \'completed\', \'plan_to_watch\', \'on_hold\', \'dropped\', \'rewatching\', \'not_interested\'))',
  );
  static const VerificationMeta _episodesWatchedMeta = const VerificationMeta(
    'episodesWatched',
  );
  late final GeneratedColumn<int> episodesWatched = GeneratedColumn<int>(
    'episodes_watched',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (episodes_watched >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (score IS NULL OR(score >= 1 AND score <= 10))',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _planRankMeta = const VerificationMeta(
    'planRank',
  );
  late final GeneratedColumn<int> planRank = GeneratedColumn<int>(
    'plan_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _progressChangedAtMeta = const VerificationMeta(
    'progressChangedAt',
  );
  late final GeneratedColumn<int> progressChangedAt = GeneratedColumn<int>(
    'progress_changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _scoreChangedAtMeta = const VerificationMeta(
    'scoreChangedAt',
  );
  late final GeneratedColumn<int> scoreChangedAt = GeneratedColumn<int>(
    'score_changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _notesChangedAtMeta = const VerificationMeta(
    'notesChangedAt',
  );
  late final GeneratedColumn<int> notesChangedAt = GeneratedColumn<int>(
    'notes_changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _linkChangedAtMeta = const VerificationMeta(
    'linkChangedAt',
  );
  late final GeneratedColumn<int> linkChangedAt = GeneratedColumn<int>(
    'link_changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression(
        'max(progress_changed_at, score_changed_at, notes_changed_at, link_changed_at)',
      ),
      false,
    ),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (max(progress_changed_at, score_changed_at, notes_changed_at, link_changed_at)) VIRTUAL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    name,
    status,
    episodesWatched,
    score,
    notes,
    planRank,
    addedAt,
    startedAt,
    progressChangedAt,
    scoreChangedAt,
    notesChangedAt,
    linkChangedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('episodes_watched')) {
      context.handle(
        _episodesWatchedMeta,
        episodesWatched.isAcceptableOrUnknown(
          data['episodes_watched']!,
          _episodesWatchedMeta,
        ),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('plan_rank')) {
      context.handle(
        _planRankMeta,
        planRank.isAcceptableOrUnknown(data['plan_rank']!, _planRankMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('progress_changed_at')) {
      context.handle(
        _progressChangedAtMeta,
        progressChangedAt.isAcceptableOrUnknown(
          data['progress_changed_at']!,
          _progressChangedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_progressChangedAtMeta);
    }
    if (data.containsKey('score_changed_at')) {
      context.handle(
        _scoreChangedAtMeta,
        scoreChangedAt.isAcceptableOrUnknown(
          data['score_changed_at']!,
          _scoreChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes_changed_at')) {
      context.handle(
        _notesChangedAtMeta,
        notesChangedAt.isAcceptableOrUnknown(
          data['notes_changed_at']!,
          _notesChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('link_changed_at')) {
      context.handle(
        _linkChangedAtMeta,
        linkChangedAt.isAcceptableOrUnknown(
          data['link_changed_at']!,
          _linkChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      episodesWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episodes_watched'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      planRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_rank'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      ),
      progressChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress_changed_at'],
      )!,
      scoreChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_changed_at'],
      )!,
      notesChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notes_changed_at'],
      )!,
      linkChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}link_changed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  EntryTable createAlias(String alias) {
    return EntryTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Entry extends DataClass implements Insertable<Entry> {
  final String entryId;
  final String? name;

  /// synced only while not linked
  final String status;
  final int episodesWatched;
  final int? score;
  final String? notes;
  final int? planRank;
  final int addedAt;
  final int? startedAt;

  /// sync merges each group on its own, the latest change wins; 0 is never changed
  final int progressChangedAt;

  /// status, episodes, started date, plan rank
  final int scoreChangedAt;
  final int notesChangedAt;
  final int linkChangedAt;

  /// the provider references
  final int? updatedAt;
  const Entry({
    required this.entryId,
    this.name,
    required this.status,
    required this.episodesWatched,
    this.score,
    this.notes,
    this.planRank,
    required this.addedAt,
    this.startedAt,
    required this.progressChangedAt,
    required this.scoreChangedAt,
    required this.notesChangedAt,
    required this.linkChangedAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['status'] = Variable<String>(status);
    map['episodes_watched'] = Variable<int>(episodesWatched);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || planRank != null) {
      map['plan_rank'] = Variable<int>(planRank);
    }
    map['added_at'] = Variable<int>(addedAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<int>(startedAt);
    }
    map['progress_changed_at'] = Variable<int>(progressChangedAt);
    map['score_changed_at'] = Variable<int>(scoreChangedAt);
    map['notes_changed_at'] = Variable<int>(notesChangedAt);
    map['link_changed_at'] = Variable<int>(linkChangedAt);
    return map;
  }

  EntryCompanion toCompanion(bool nullToAbsent) {
    return EntryCompanion(
      entryId: Value(entryId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      status: Value(status),
      episodesWatched: Value(episodesWatched),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      planRank: planRank == null && nullToAbsent
          ? const Value.absent()
          : Value(planRank),
      addedAt: Value(addedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      progressChangedAt: Value(progressChangedAt),
      scoreChangedAt: Value(scoreChangedAt),
      notesChangedAt: Value(notesChangedAt),
      linkChangedAt: Value(linkChangedAt),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      entryId: serializer.fromJson<String>(json['entry_id']),
      name: serializer.fromJson<String?>(json['name']),
      status: serializer.fromJson<String>(json['status']),
      episodesWatched: serializer.fromJson<int>(json['episodes_watched']),
      score: serializer.fromJson<int?>(json['score']),
      notes: serializer.fromJson<String?>(json['notes']),
      planRank: serializer.fromJson<int?>(json['plan_rank']),
      addedAt: serializer.fromJson<int>(json['added_at']),
      startedAt: serializer.fromJson<int?>(json['started_at']),
      progressChangedAt: serializer.fromJson<int>(json['progress_changed_at']),
      scoreChangedAt: serializer.fromJson<int>(json['score_changed_at']),
      notesChangedAt: serializer.fromJson<int>(json['notes_changed_at']),
      linkChangedAt: serializer.fromJson<int>(json['link_changed_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'name': serializer.toJson<String?>(name),
      'status': serializer.toJson<String>(status),
      'episodes_watched': serializer.toJson<int>(episodesWatched),
      'score': serializer.toJson<int?>(score),
      'notes': serializer.toJson<String?>(notes),
      'plan_rank': serializer.toJson<int?>(planRank),
      'added_at': serializer.toJson<int>(addedAt),
      'started_at': serializer.toJson<int?>(startedAt),
      'progress_changed_at': serializer.toJson<int>(progressChangedAt),
      'score_changed_at': serializer.toJson<int>(scoreChangedAt),
      'notes_changed_at': serializer.toJson<int>(notesChangedAt),
      'link_changed_at': serializer.toJson<int>(linkChangedAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
    };
  }

  Entry copyWith({
    String? entryId,
    Value<String?> name = const Value.absent(),
    String? status,
    int? episodesWatched,
    Value<int?> score = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> planRank = const Value.absent(),
    int? addedAt,
    Value<int?> startedAt = const Value.absent(),
    int? progressChangedAt,
    int? scoreChangedAt,
    int? notesChangedAt,
    int? linkChangedAt,
    Value<int?> updatedAt = const Value.absent(),
  }) => Entry(
    entryId: entryId ?? this.entryId,
    name: name.present ? name.value : this.name,
    status: status ?? this.status,
    episodesWatched: episodesWatched ?? this.episodesWatched,
    score: score.present ? score.value : this.score,
    notes: notes.present ? notes.value : this.notes,
    planRank: planRank.present ? planRank.value : this.planRank,
    addedAt: addedAt ?? this.addedAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    progressChangedAt: progressChangedAt ?? this.progressChangedAt,
    scoreChangedAt: scoreChangedAt ?? this.scoreChangedAt,
    notesChangedAt: notesChangedAt ?? this.notesChangedAt,
    linkChangedAt: linkChangedAt ?? this.linkChangedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('entryId: $entryId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('episodesWatched: $episodesWatched, ')
          ..write('score: $score, ')
          ..write('notes: $notes, ')
          ..write('planRank: $planRank, ')
          ..write('addedAt: $addedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('progressChangedAt: $progressChangedAt, ')
          ..write('scoreChangedAt: $scoreChangedAt, ')
          ..write('notesChangedAt: $notesChangedAt, ')
          ..write('linkChangedAt: $linkChangedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    name,
    status,
    episodesWatched,
    score,
    notes,
    planRank,
    addedAt,
    startedAt,
    progressChangedAt,
    scoreChangedAt,
    notesChangedAt,
    linkChangedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.entryId == this.entryId &&
          other.name == this.name &&
          other.status == this.status &&
          other.episodesWatched == this.episodesWatched &&
          other.score == this.score &&
          other.notes == this.notes &&
          other.planRank == this.planRank &&
          other.addedAt == this.addedAt &&
          other.startedAt == this.startedAt &&
          other.progressChangedAt == this.progressChangedAt &&
          other.scoreChangedAt == this.scoreChangedAt &&
          other.notesChangedAt == this.notesChangedAt &&
          other.linkChangedAt == this.linkChangedAt &&
          other.updatedAt == this.updatedAt);
}

class EntryCompanion extends UpdateCompanion<Entry> {
  final Value<String> entryId;
  final Value<String?> name;
  final Value<String> status;
  final Value<int> episodesWatched;
  final Value<int?> score;
  final Value<String?> notes;
  final Value<int?> planRank;
  final Value<int> addedAt;
  final Value<int?> startedAt;
  final Value<int> progressChangedAt;
  final Value<int> scoreChangedAt;
  final Value<int> notesChangedAt;
  final Value<int> linkChangedAt;
  final Value<int> rowid;
  const EntryCompanion({
    this.entryId = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.episodesWatched = const Value.absent(),
    this.score = const Value.absent(),
    this.notes = const Value.absent(),
    this.planRank = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.progressChangedAt = const Value.absent(),
    this.scoreChangedAt = const Value.absent(),
    this.notesChangedAt = const Value.absent(),
    this.linkChangedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryCompanion.insert({
    required String entryId,
    this.name = const Value.absent(),
    required String status,
    this.episodesWatched = const Value.absent(),
    this.score = const Value.absent(),
    this.notes = const Value.absent(),
    this.planRank = const Value.absent(),
    required int addedAt,
    this.startedAt = const Value.absent(),
    required int progressChangedAt,
    this.scoreChangedAt = const Value.absent(),
    this.notesChangedAt = const Value.absent(),
    this.linkChangedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       status = Value(status),
       addedAt = Value(addedAt),
       progressChangedAt = Value(progressChangedAt);
  static Insertable<Entry> custom({
    Expression<String>? entryId,
    Expression<String>? name,
    Expression<String>? status,
    Expression<int>? episodesWatched,
    Expression<int>? score,
    Expression<String>? notes,
    Expression<int>? planRank,
    Expression<int>? addedAt,
    Expression<int>? startedAt,
    Expression<int>? progressChangedAt,
    Expression<int>? scoreChangedAt,
    Expression<int>? notesChangedAt,
    Expression<int>? linkChangedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (episodesWatched != null) 'episodes_watched': episodesWatched,
      if (score != null) 'score': score,
      if (notes != null) 'notes': notes,
      if (planRank != null) 'plan_rank': planRank,
      if (addedAt != null) 'added_at': addedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (progressChangedAt != null) 'progress_changed_at': progressChangedAt,
      if (scoreChangedAt != null) 'score_changed_at': scoreChangedAt,
      if (notesChangedAt != null) 'notes_changed_at': notesChangedAt,
      if (linkChangedAt != null) 'link_changed_at': linkChangedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryCompanion copyWith({
    Value<String>? entryId,
    Value<String?>? name,
    Value<String>? status,
    Value<int>? episodesWatched,
    Value<int?>? score,
    Value<String?>? notes,
    Value<int?>? planRank,
    Value<int>? addedAt,
    Value<int?>? startedAt,
    Value<int>? progressChangedAt,
    Value<int>? scoreChangedAt,
    Value<int>? notesChangedAt,
    Value<int>? linkChangedAt,
    Value<int>? rowid,
  }) {
    return EntryCompanion(
      entryId: entryId ?? this.entryId,
      name: name ?? this.name,
      status: status ?? this.status,
      episodesWatched: episodesWatched ?? this.episodesWatched,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      planRank: planRank ?? this.planRank,
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      progressChangedAt: progressChangedAt ?? this.progressChangedAt,
      scoreChangedAt: scoreChangedAt ?? this.scoreChangedAt,
      notesChangedAt: notesChangedAt ?? this.notesChangedAt,
      linkChangedAt: linkChangedAt ?? this.linkChangedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (episodesWatched.present) {
      map['episodes_watched'] = Variable<int>(episodesWatched.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (planRank.present) {
      map['plan_rank'] = Variable<int>(planRank.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (progressChangedAt.present) {
      map['progress_changed_at'] = Variable<int>(progressChangedAt.value);
    }
    if (scoreChangedAt.present) {
      map['score_changed_at'] = Variable<int>(scoreChangedAt.value);
    }
    if (notesChangedAt.present) {
      map['notes_changed_at'] = Variable<int>(notesChangedAt.value);
    }
    if (linkChangedAt.present) {
      map['link_changed_at'] = Variable<int>(linkChangedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryCompanion(')
          ..write('entryId: $entryId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('episodesWatched: $episodesWatched, ')
          ..write('score: $score, ')
          ..write('notes: $notes, ')
          ..write('planRank: $planRank, ')
          ..write('addedAt: $addedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('progressChangedAt: $progressChangedAt, ')
          ..write('scoreChangedAt: $scoreChangedAt, ')
          ..write('notesChangedAt: $notesChangedAt, ')
          ..write('linkChangedAt: $linkChangedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EntryReferenceTable extends Table
    with TableInfo<EntryReferenceTable, EntryReference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EntryReferenceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES entry(entry_id)ON DELETE CASCADE',
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (provider IN (\'mal\', \'anilist\'))',
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, provider, providerId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_reference';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, provider};
  @override
  EntryReference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryReference(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
    );
  }

  @override
  EntryReferenceTable createAlias(String alias) {
    return EntryReferenceTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(entry_id, provider)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class EntryReference extends DataClass implements Insertable<EntryReference> {
  final String entryId;
  final String provider;
  final int providerId;
  const EntryReference({
    required this.entryId,
    required this.provider,
    required this.providerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    return map;
  }

  EntryReferenceCompanion toCompanion(bool nullToAbsent) {
    return EntryReferenceCompanion(
      entryId: Value(entryId),
      provider: Value(provider),
      providerId: Value(providerId),
    );
  }

  factory EntryReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryReference(
      entryId: serializer.fromJson<String>(json['entry_id']),
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
    };
  }

  EntryReference copyWith({
    String? entryId,
    String? provider,
    int? providerId,
  }) => EntryReference(
    entryId: entryId ?? this.entryId,
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
  );
  EntryReference copyWithCompanion(EntryReferenceCompanion data) {
    return EntryReference(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryReference(')
          ..write('entryId: $entryId, ')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, provider, providerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryReference &&
          other.entryId == this.entryId &&
          other.provider == this.provider &&
          other.providerId == this.providerId);
}

class EntryReferenceCompanion extends UpdateCompanion<EntryReference> {
  final Value<String> entryId;
  final Value<String> provider;
  final Value<int> providerId;
  final Value<int> rowid;
  const EntryReferenceCompanion({
    this.entryId = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryReferenceCompanion.insert({
    required String entryId,
    required String provider,
    required int providerId,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       provider = Value(provider),
       providerId = Value(providerId);
  static Insertable<EntryReference> custom({
    Expression<String>? entryId,
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryReferenceCompanion copyWith({
    Value<String>? entryId,
    Value<String>? provider,
    Value<int>? providerId,
    Value<int>? rowid,
  }) {
    return EntryReferenceCompanion(
      entryId: entryId ?? this.entryId,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryReferenceCompanion(')
          ..write('entryId: $entryId, ')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MatchDeclineTable extends Table
    with TableInfo<MatchDeclineTable, MatchDecline> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MatchDeclineTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES entry(entry_id)ON DELETE CASCADE',
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (provider IN (\'mal\', \'anilist\'))',
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _declinedAtMeta = const VerificationMeta(
    'declinedAt',
  );
  late final GeneratedColumn<int> declinedAt = GeneratedColumn<int>(
    'declined_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    provider,
    providerId,
    declinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_decline';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchDecline> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('declined_at')) {
      context.handle(
        _declinedAtMeta,
        declinedAt.isAcceptableOrUnknown(data['declined_at']!, _declinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_declinedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, provider, providerId};
  @override
  MatchDecline map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchDecline(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      declinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}declined_at'],
      )!,
    );
  }

  @override
  MatchDeclineTable createAlias(String alias) {
    return MatchDeclineTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(entry_id, provider, provider_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MatchDecline extends DataClass implements Insertable<MatchDecline> {
  final String entryId;
  final String provider;
  final int providerId;
  final int declinedAt;
  const MatchDecline({
    required this.entryId,
    required this.provider,
    required this.providerId,
    required this.declinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['declined_at'] = Variable<int>(declinedAt);
    return map;
  }

  MatchDeclineCompanion toCompanion(bool nullToAbsent) {
    return MatchDeclineCompanion(
      entryId: Value(entryId),
      provider: Value(provider),
      providerId: Value(providerId),
      declinedAt: Value(declinedAt),
    );
  }

  factory MatchDecline.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchDecline(
      entryId: serializer.fromJson<String>(json['entry_id']),
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
      declinedAt: serializer.fromJson<int>(json['declined_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
      'declined_at': serializer.toJson<int>(declinedAt),
    };
  }

  MatchDecline copyWith({
    String? entryId,
    String? provider,
    int? providerId,
    int? declinedAt,
  }) => MatchDecline(
    entryId: entryId ?? this.entryId,
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    declinedAt: declinedAt ?? this.declinedAt,
  );
  MatchDecline copyWithCompanion(MatchDeclineCompanion data) {
    return MatchDecline(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      declinedAt: data.declinedAt.present
          ? data.declinedAt.value
          : this.declinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchDecline(')
          ..write('entryId: $entryId, ')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('declinedAt: $declinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, provider, providerId, declinedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchDecline &&
          other.entryId == this.entryId &&
          other.provider == this.provider &&
          other.providerId == this.providerId &&
          other.declinedAt == this.declinedAt);
}

class MatchDeclineCompanion extends UpdateCompanion<MatchDecline> {
  final Value<String> entryId;
  final Value<String> provider;
  final Value<int> providerId;
  final Value<int> declinedAt;
  final Value<int> rowid;
  const MatchDeclineCompanion({
    this.entryId = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.declinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchDeclineCompanion.insert({
    required String entryId,
    required String provider,
    required int providerId,
    required int declinedAt,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       provider = Value(provider),
       providerId = Value(providerId),
       declinedAt = Value(declinedAt);
  static Insertable<MatchDecline> custom({
    Expression<String>? entryId,
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<int>? declinedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (declinedAt != null) 'declined_at': declinedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchDeclineCompanion copyWith({
    Value<String>? entryId,
    Value<String>? provider,
    Value<int>? providerId,
    Value<int>? declinedAt,
    Value<int>? rowid,
  }) {
    return MatchDeclineCompanion(
      entryId: entryId ?? this.entryId,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      declinedAt: declinedAt ?? this.declinedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (declinedAt.present) {
      map['declined_at'] = Variable<int>(declinedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchDeclineCompanion(')
          ..write('entryId: $entryId, ')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('declinedAt: $declinedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CompletionTable extends Table
    with TableInfo<CompletionTable, Completion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CompletionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _watchNumberMeta = const VerificationMeta(
    'watchNumber',
  );
  late final GeneratedColumn<int> watchNumber = GeneratedColumn<int>(
    'watch_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _episodesWatchedMeta = const VerificationMeta(
    'episodesWatched',
  );
  late final GeneratedColumn<int> episodesWatched = GeneratedColumn<int>(
    'episodes_watched',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _minutesPerEpisodeMeta = const VerificationMeta(
    'minutesPerEpisode',
  );
  late final GeneratedColumn<int> minutesPerEpisode = GeneratedColumn<int>(
    'minutes_per_episode',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _isEstimatedMeta = const VerificationMeta(
    'isEstimated',
  );
  late final GeneratedColumn<bool> isEstimated = GeneratedColumn<bool>(
    'is_estimated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    watchNumber,
    completedAt,
    episodesWatched,
    minutesPerEpisode,
    isEstimated,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completion';
  @override
  VerificationContext validateIntegrity(
    Insertable<Completion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('watch_number')) {
      context.handle(
        _watchNumberMeta,
        watchNumber.isAcceptableOrUnknown(
          data['watch_number']!,
          _watchNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_watchNumberMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('episodes_watched')) {
      context.handle(
        _episodesWatchedMeta,
        episodesWatched.isAcceptableOrUnknown(
          data['episodes_watched']!,
          _episodesWatchedMeta,
        ),
      );
    }
    if (data.containsKey('minutes_per_episode')) {
      context.handle(
        _minutesPerEpisodeMeta,
        minutesPerEpisode.isAcceptableOrUnknown(
          data['minutes_per_episode']!,
          _minutesPerEpisodeMeta,
        ),
      );
    }
    if (data.containsKey('is_estimated')) {
      context.handle(
        _isEstimatedMeta,
        isEstimated.isAcceptableOrUnknown(
          data['is_estimated']!,
          _isEstimatedMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, watchNumber};
  @override
  Completion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Completion(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      watchNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}watch_number'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      )!,
      episodesWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episodes_watched'],
      )!,
      minutesPerEpisode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_per_episode'],
      ),
      isEstimated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimated'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
    );
  }

  @override
  CompletionTable createAlias(String alias) {
    return CompletionTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(entry_id, watch_number)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Completion extends DataClass implements Insertable<Completion> {
  final String entryId;
  final int watchNumber;

  /// 0 first watch, 1 first rewatch
  final int completedAt;
  final int episodesWatched;
  final int? minutesPerEpisode;

  /// null: stats use 24
  final bool isEstimated;
  final String? name;
  const Completion({
    required this.entryId,
    required this.watchNumber,
    required this.completedAt,
    required this.episodesWatched,
    this.minutesPerEpisode,
    required this.isEstimated,
    this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['watch_number'] = Variable<int>(watchNumber);
    map['completed_at'] = Variable<int>(completedAt);
    map['episodes_watched'] = Variable<int>(episodesWatched);
    if (!nullToAbsent || minutesPerEpisode != null) {
      map['minutes_per_episode'] = Variable<int>(minutesPerEpisode);
    }
    map['is_estimated'] = Variable<bool>(isEstimated);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  CompletionCompanion toCompanion(bool nullToAbsent) {
    return CompletionCompanion(
      entryId: Value(entryId),
      watchNumber: Value(watchNumber),
      completedAt: Value(completedAt),
      episodesWatched: Value(episodesWatched),
      minutesPerEpisode: minutesPerEpisode == null && nullToAbsent
          ? const Value.absent()
          : Value(minutesPerEpisode),
      isEstimated: Value(isEstimated),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory Completion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Completion(
      entryId: serializer.fromJson<String>(json['entry_id']),
      watchNumber: serializer.fromJson<int>(json['watch_number']),
      completedAt: serializer.fromJson<int>(json['completed_at']),
      episodesWatched: serializer.fromJson<int>(json['episodes_watched']),
      minutesPerEpisode: serializer.fromJson<int?>(json['minutes_per_episode']),
      isEstimated: serializer.fromJson<bool>(json['is_estimated']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'watch_number': serializer.toJson<int>(watchNumber),
      'completed_at': serializer.toJson<int>(completedAt),
      'episodes_watched': serializer.toJson<int>(episodesWatched),
      'minutes_per_episode': serializer.toJson<int?>(minutesPerEpisode),
      'is_estimated': serializer.toJson<bool>(isEstimated),
      'name': serializer.toJson<String?>(name),
    };
  }

  Completion copyWith({
    String? entryId,
    int? watchNumber,
    int? completedAt,
    int? episodesWatched,
    Value<int?> minutesPerEpisode = const Value.absent(),
    bool? isEstimated,
    Value<String?> name = const Value.absent(),
  }) => Completion(
    entryId: entryId ?? this.entryId,
    watchNumber: watchNumber ?? this.watchNumber,
    completedAt: completedAt ?? this.completedAt,
    episodesWatched: episodesWatched ?? this.episodesWatched,
    minutesPerEpisode: minutesPerEpisode.present
        ? minutesPerEpisode.value
        : this.minutesPerEpisode,
    isEstimated: isEstimated ?? this.isEstimated,
    name: name.present ? name.value : this.name,
  );
  Completion copyWithCompanion(CompletionCompanion data) {
    return Completion(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      watchNumber: data.watchNumber.present
          ? data.watchNumber.value
          : this.watchNumber,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      episodesWatched: data.episodesWatched.present
          ? data.episodesWatched.value
          : this.episodesWatched,
      minutesPerEpisode: data.minutesPerEpisode.present
          ? data.minutesPerEpisode.value
          : this.minutesPerEpisode,
      isEstimated: data.isEstimated.present
          ? data.isEstimated.value
          : this.isEstimated,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Completion(')
          ..write('entryId: $entryId, ')
          ..write('watchNumber: $watchNumber, ')
          ..write('completedAt: $completedAt, ')
          ..write('episodesWatched: $episodesWatched, ')
          ..write('minutesPerEpisode: $minutesPerEpisode, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    watchNumber,
    completedAt,
    episodesWatched,
    minutesPerEpisode,
    isEstimated,
    name,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Completion &&
          other.entryId == this.entryId &&
          other.watchNumber == this.watchNumber &&
          other.completedAt == this.completedAt &&
          other.episodesWatched == this.episodesWatched &&
          other.minutesPerEpisode == this.minutesPerEpisode &&
          other.isEstimated == this.isEstimated &&
          other.name == this.name);
}

class CompletionCompanion extends UpdateCompanion<Completion> {
  final Value<String> entryId;
  final Value<int> watchNumber;
  final Value<int> completedAt;
  final Value<int> episodesWatched;
  final Value<int?> minutesPerEpisode;
  final Value<bool> isEstimated;
  final Value<String?> name;
  final Value<int> rowid;
  const CompletionCompanion({
    this.entryId = const Value.absent(),
    this.watchNumber = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.episodesWatched = const Value.absent(),
    this.minutesPerEpisode = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionCompanion.insert({
    required String entryId,
    required int watchNumber,
    required int completedAt,
    this.episodesWatched = const Value.absent(),
    this.minutesPerEpisode = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       watchNumber = Value(watchNumber),
       completedAt = Value(completedAt);
  static Insertable<Completion> custom({
    Expression<String>? entryId,
    Expression<int>? watchNumber,
    Expression<int>? completedAt,
    Expression<int>? episodesWatched,
    Expression<int>? minutesPerEpisode,
    Expression<bool>? isEstimated,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (watchNumber != null) 'watch_number': watchNumber,
      if (completedAt != null) 'completed_at': completedAt,
      if (episodesWatched != null) 'episodes_watched': episodesWatched,
      if (minutesPerEpisode != null) 'minutes_per_episode': minutesPerEpisode,
      if (isEstimated != null) 'is_estimated': isEstimated,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionCompanion copyWith({
    Value<String>? entryId,
    Value<int>? watchNumber,
    Value<int>? completedAt,
    Value<int>? episodesWatched,
    Value<int?>? minutesPerEpisode,
    Value<bool>? isEstimated,
    Value<String?>? name,
    Value<int>? rowid,
  }) {
    return CompletionCompanion(
      entryId: entryId ?? this.entryId,
      watchNumber: watchNumber ?? this.watchNumber,
      completedAt: completedAt ?? this.completedAt,
      episodesWatched: episodesWatched ?? this.episodesWatched,
      minutesPerEpisode: minutesPerEpisode ?? this.minutesPerEpisode,
      isEstimated: isEstimated ?? this.isEstimated,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (watchNumber.present) {
      map['watch_number'] = Variable<int>(watchNumber.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (episodesWatched.present) {
      map['episodes_watched'] = Variable<int>(episodesWatched.value);
    }
    if (minutesPerEpisode.present) {
      map['minutes_per_episode'] = Variable<int>(minutesPerEpisode.value);
    }
    if (isEstimated.present) {
      map['is_estimated'] = Variable<bool>(isEstimated.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionCompanion(')
          ..write('entryId: $entryId, ')
          ..write('watchNumber: $watchNumber, ')
          ..write('completedAt: $completedAt, ')
          ..write('episodesWatched: $episodesWatched, ')
          ..write('minutesPerEpisode: $minutesPerEpisode, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AlertTable extends Table with TableInfo<AlertTable, Alert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AlertTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _relatedProviderMeta = const VerificationMeta(
    'relatedProvider',
  );
  late final GeneratedColumn<String> relatedProvider = GeneratedColumn<String>(
    'related_provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (related_provider IN (\'mal\', \'anilist\'))',
  );
  static const VerificationMeta _relatedProviderIdMeta = const VerificationMeta(
    'relatedProviderId',
  );
  late final GeneratedColumn<int> relatedProviderId = GeneratedColumn<int>(
    'related_provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (type IN (\'sequel\', \'side_story\', \'spin_off\', \'movie\', \'started_airing\', \'earlier_unmarked\'))',
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  late final GeneratedColumn<bool> seen = GeneratedColumn<bool>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _dismissedMeta = const VerificationMeta(
    'dismissed',
  );
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
    'dismissed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    relatedProvider,
    relatedProviderId,
    type,
    seen,
    dismissed,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alert';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('related_provider')) {
      context.handle(
        _relatedProviderMeta,
        relatedProvider.isAcceptableOrUnknown(
          data['related_provider']!,
          _relatedProviderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedProviderMeta);
    }
    if (data.containsKey('related_provider_id')) {
      context.handle(
        _relatedProviderIdMeta,
        relatedProviderId.isAcceptableOrUnknown(
          data['related_provider_id']!,
          _relatedProviderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedProviderIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    }
    if (data.containsKey('dismissed')) {
      context.handle(
        _dismissedMeta,
        dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    entryId,
    relatedProvider,
    relatedProviderId,
    type,
  };
  @override
  Alert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alert(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      relatedProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_provider'],
      )!,
      relatedProviderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}related_provider_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}seen'],
      )!,
      dismissed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dismissed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  AlertTable createAlias(String alias) {
    return AlertTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(entry_id, related_provider, related_provider_id, type)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Alert extends DataClass implements Insertable<Alert> {
  final String entryId;
  final String relatedProvider;
  final int relatedProviderId;
  final String type;
  final bool seen;
  final bool dismissed;
  final int createdAt;
  const Alert({
    required this.entryId,
    required this.relatedProvider,
    required this.relatedProviderId,
    required this.type,
    required this.seen,
    required this.dismissed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['related_provider'] = Variable<String>(relatedProvider);
    map['related_provider_id'] = Variable<int>(relatedProviderId);
    map['type'] = Variable<String>(type);
    map['seen'] = Variable<bool>(seen);
    map['dismissed'] = Variable<bool>(dismissed);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AlertCompanion toCompanion(bool nullToAbsent) {
    return AlertCompanion(
      entryId: Value(entryId),
      relatedProvider: Value(relatedProvider),
      relatedProviderId: Value(relatedProviderId),
      type: Value(type),
      seen: Value(seen),
      dismissed: Value(dismissed),
      createdAt: Value(createdAt),
    );
  }

  factory Alert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alert(
      entryId: serializer.fromJson<String>(json['entry_id']),
      relatedProvider: serializer.fromJson<String>(json['related_provider']),
      relatedProviderId: serializer.fromJson<int>(json['related_provider_id']),
      type: serializer.fromJson<String>(json['type']),
      seen: serializer.fromJson<bool>(json['seen']),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'related_provider': serializer.toJson<String>(relatedProvider),
      'related_provider_id': serializer.toJson<int>(relatedProviderId),
      'type': serializer.toJson<String>(type),
      'seen': serializer.toJson<bool>(seen),
      'dismissed': serializer.toJson<bool>(dismissed),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  Alert copyWith({
    String? entryId,
    String? relatedProvider,
    int? relatedProviderId,
    String? type,
    bool? seen,
    bool? dismissed,
    int? createdAt,
  }) => Alert(
    entryId: entryId ?? this.entryId,
    relatedProvider: relatedProvider ?? this.relatedProvider,
    relatedProviderId: relatedProviderId ?? this.relatedProviderId,
    type: type ?? this.type,
    seen: seen ?? this.seen,
    dismissed: dismissed ?? this.dismissed,
    createdAt: createdAt ?? this.createdAt,
  );
  Alert copyWithCompanion(AlertCompanion data) {
    return Alert(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      relatedProvider: data.relatedProvider.present
          ? data.relatedProvider.value
          : this.relatedProvider,
      relatedProviderId: data.relatedProviderId.present
          ? data.relatedProviderId.value
          : this.relatedProviderId,
      type: data.type.present ? data.type.value : this.type,
      seen: data.seen.present ? data.seen.value : this.seen,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alert(')
          ..write('entryId: $entryId, ')
          ..write('relatedProvider: $relatedProvider, ')
          ..write('relatedProviderId: $relatedProviderId, ')
          ..write('type: $type, ')
          ..write('seen: $seen, ')
          ..write('dismissed: $dismissed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    relatedProvider,
    relatedProviderId,
    type,
    seen,
    dismissed,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          other.entryId == this.entryId &&
          other.relatedProvider == this.relatedProvider &&
          other.relatedProviderId == this.relatedProviderId &&
          other.type == this.type &&
          other.seen == this.seen &&
          other.dismissed == this.dismissed &&
          other.createdAt == this.createdAt);
}

class AlertCompanion extends UpdateCompanion<Alert> {
  final Value<String> entryId;
  final Value<String> relatedProvider;
  final Value<int> relatedProviderId;
  final Value<String> type;
  final Value<bool> seen;
  final Value<bool> dismissed;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AlertCompanion({
    this.entryId = const Value.absent(),
    this.relatedProvider = const Value.absent(),
    this.relatedProviderId = const Value.absent(),
    this.type = const Value.absent(),
    this.seen = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertCompanion.insert({
    required String entryId,
    required String relatedProvider,
    required int relatedProviderId,
    required String type,
    this.seen = const Value.absent(),
    this.dismissed = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       relatedProvider = Value(relatedProvider),
       relatedProviderId = Value(relatedProviderId),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<Alert> custom({
    Expression<String>? entryId,
    Expression<String>? relatedProvider,
    Expression<int>? relatedProviderId,
    Expression<String>? type,
    Expression<bool>? seen,
    Expression<bool>? dismissed,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (relatedProvider != null) 'related_provider': relatedProvider,
      if (relatedProviderId != null) 'related_provider_id': relatedProviderId,
      if (type != null) 'type': type,
      if (seen != null) 'seen': seen,
      if (dismissed != null) 'dismissed': dismissed,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertCompanion copyWith({
    Value<String>? entryId,
    Value<String>? relatedProvider,
    Value<int>? relatedProviderId,
    Value<String>? type,
    Value<bool>? seen,
    Value<bool>? dismissed,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return AlertCompanion(
      entryId: entryId ?? this.entryId,
      relatedProvider: relatedProvider ?? this.relatedProvider,
      relatedProviderId: relatedProviderId ?? this.relatedProviderId,
      type: type ?? this.type,
      seen: seen ?? this.seen,
      dismissed: dismissed ?? this.dismissed,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (relatedProvider.present) {
      map['related_provider'] = Variable<String>(relatedProvider.value);
    }
    if (relatedProviderId.present) {
      map['related_provider_id'] = Variable<int>(relatedProviderId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (seen.present) {
      map['seen'] = Variable<bool>(seen.value);
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertCompanion(')
          ..write('entryId: $entryId, ')
          ..write('relatedProvider: $relatedProvider, ')
          ..write('relatedProviderId: $relatedProviderId, ')
          ..write('type: $type, ')
          ..write('seen: $seen, ')
          ..write('dismissed: $dismissed, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EntryAliasTable extends Table
    with TableInfo<EntryAliasTable, EntryAlias> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EntryAliasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _aliasIdMeta = const VerificationMeta(
    'aliasId',
  );
  late final GeneratedColumn<String> aliasId = GeneratedColumn<String>(
    'alias_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [aliasId, entryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_alias';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryAlias> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alias_id')) {
      context.handle(
        _aliasIdMeta,
        aliasId.isAcceptableOrUnknown(data['alias_id']!, _aliasIdMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasIdMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {aliasId};
  @override
  EntryAlias map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryAlias(
      aliasId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias_id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
    );
  }

  @override
  EntryAliasTable createAlias(String alias) {
    return EntryAliasTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EntryAlias extends DataClass implements Insertable<EntryAlias> {
  final String aliasId;
  final String entryId;
  const EntryAlias({required this.aliasId, required this.entryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alias_id'] = Variable<String>(aliasId);
    map['entry_id'] = Variable<String>(entryId);
    return map;
  }

  EntryAliasCompanion toCompanion(bool nullToAbsent) {
    return EntryAliasCompanion(
      aliasId: Value(aliasId),
      entryId: Value(entryId),
    );
  }

  factory EntryAlias.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryAlias(
      aliasId: serializer.fromJson<String>(json['alias_id']),
      entryId: serializer.fromJson<String>(json['entry_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alias_id': serializer.toJson<String>(aliasId),
      'entry_id': serializer.toJson<String>(entryId),
    };
  }

  EntryAlias copyWith({String? aliasId, String? entryId}) => EntryAlias(
    aliasId: aliasId ?? this.aliasId,
    entryId: entryId ?? this.entryId,
  );
  EntryAlias copyWithCompanion(EntryAliasCompanion data) {
    return EntryAlias(
      aliasId: data.aliasId.present ? data.aliasId.value : this.aliasId,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryAlias(')
          ..write('aliasId: $aliasId, ')
          ..write('entryId: $entryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(aliasId, entryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryAlias &&
          other.aliasId == this.aliasId &&
          other.entryId == this.entryId);
}

class EntryAliasCompanion extends UpdateCompanion<EntryAlias> {
  final Value<String> aliasId;
  final Value<String> entryId;
  final Value<int> rowid;
  const EntryAliasCompanion({
    this.aliasId = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryAliasCompanion.insert({
    required String aliasId,
    required String entryId,
    this.rowid = const Value.absent(),
  }) : aliasId = Value(aliasId),
       entryId = Value(entryId);
  static Insertable<EntryAlias> custom({
    Expression<String>? aliasId,
    Expression<String>? entryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (aliasId != null) 'alias_id': aliasId,
      if (entryId != null) 'entry_id': entryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryAliasCompanion copyWith({
    Value<String>? aliasId,
    Value<String>? entryId,
    Value<int>? rowid,
  }) {
    return EntryAliasCompanion(
      aliasId: aliasId ?? this.aliasId,
      entryId: entryId ?? this.entryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (aliasId.present) {
      map['alias_id'] = Variable<String>(aliasId.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryAliasCompanion(')
          ..write('aliasId: $aliasId, ')
          ..write('entryId: $entryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DeletionTable extends Table with TableInfo<DeletionTable, Deletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DeletionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deletion';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  Deletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deletion(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  DeletionTable createAlias(String alias) {
    return DeletionTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Deletion extends DataClass implements Insertable<Deletion> {
  final String entryId;
  final int deletedAt;
  const Deletion({required this.entryId, required this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['deleted_at'] = Variable<int>(deletedAt);
    return map;
  }

  DeletionCompanion toCompanion(bool nullToAbsent) {
    return DeletionCompanion(
      entryId: Value(entryId),
      deletedAt: Value(deletedAt),
    );
  }

  factory Deletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deletion(
      entryId: serializer.fromJson<String>(json['entry_id']),
      deletedAt: serializer.fromJson<int>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'deleted_at': serializer.toJson<int>(deletedAt),
    };
  }

  Deletion copyWith({String? entryId, int? deletedAt}) => Deletion(
    entryId: entryId ?? this.entryId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  Deletion copyWithCompanion(DeletionCompanion data) {
    return Deletion(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deletion(')
          ..write('entryId: $entryId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deletion &&
          other.entryId == this.entryId &&
          other.deletedAt == this.deletedAt);
}

class DeletionCompanion extends UpdateCompanion<Deletion> {
  final Value<String> entryId;
  final Value<int> deletedAt;
  final Value<int> rowid;
  const DeletionCompanion({
    this.entryId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletionCompanion.insert({
    required String entryId,
    required int deletedAt,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       deletedAt = Value(deletedAt);
  static Insertable<Deletion> custom({
    Expression<String>? entryId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletionCompanion copyWith({
    Value<String>? entryId,
    Value<int>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletionCompanion(
      entryId: entryId ?? this.entryId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletionCompanion(')
          ..write('entryId: $entryId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SettingTable extends Table with TableInfo<SettingTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SettingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  SettingTable createAlias(String alias) {
    return SettingTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final int updatedAt;
  const Setting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingCompanion toCompanion(bool nullToAbsent) {
    return SettingCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  Setting copyWith({String? key, String? value, int? updatedAt}) => Setting(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Setting copyWithCompanion(SettingCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SettingCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DeviceTable extends Table with TableInfo<DeviceTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DeviceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _driveVersionMeta = const VerificationMeta(
    'driveVersion',
  );
  late final GeneratedColumn<String> driveVersion = GeneratedColumn<String>(
    'drive_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _driveHashMeta = const VerificationMeta(
    'driveHash',
  );
  late final GeneratedColumn<String> driveHash = GeneratedColumn<String>(
    'drive_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _newestSeenAtMeta = const VerificationMeta(
    'newestSeenAt',
  );
  late final GeneratedColumn<int> newestSeenAt = GeneratedColumn<int>(
    'newest_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    driveVersion,
    driveHash,
    newestSeenAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('drive_version')) {
      context.handle(
        _driveVersionMeta,
        driveVersion.isAcceptableOrUnknown(
          data['drive_version']!,
          _driveVersionMeta,
        ),
      );
    }
    if (data.containsKey('drive_hash')) {
      context.handle(
        _driveHashMeta,
        driveHash.isAcceptableOrUnknown(data['drive_hash']!, _driveHashMeta),
      );
    }
    if (data.containsKey('newest_seen_at')) {
      context.handle(
        _newestSeenAtMeta,
        newestSeenAt.isAcceptableOrUnknown(
          data['newest_seen_at']!,
          _newestSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      driveVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_version'],
      ),
      driveHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_hash'],
      ),
      newestSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}newest_seen_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  DeviceTable createAlias(String alias) {
    return DeviceTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Device extends DataClass implements Insertable<Device> {
  final String deviceId;
  final String? driveVersion;

  /// id and version of the drive file last seen
  final String? driveHash;

  /// hash of the record as it is on drive
  final int newestSeenAt;

  /// newest change time seen in a merge
  final int? lastSyncedAt;
  const Device({
    required this.deviceId,
    this.driveVersion,
    this.driveHash,
    required this.newestSeenAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || driveVersion != null) {
      map['drive_version'] = Variable<String>(driveVersion);
    }
    if (!nullToAbsent || driveHash != null) {
      map['drive_hash'] = Variable<String>(driveHash);
    }
    map['newest_seen_at'] = Variable<int>(newestSeenAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    return map;
  }

  DeviceCompanion toCompanion(bool nullToAbsent) {
    return DeviceCompanion(
      deviceId: Value(deviceId),
      driveVersion: driveVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(driveVersion),
      driveHash: driveHash == null && nullToAbsent
          ? const Value.absent()
          : Value(driveHash),
      newestSeenAt: Value(newestSeenAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      deviceId: serializer.fromJson<String>(json['device_id']),
      driveVersion: serializer.fromJson<String?>(json['drive_version']),
      driveHash: serializer.fromJson<String?>(json['drive_hash']),
      newestSeenAt: serializer.fromJson<int>(json['newest_seen_at']),
      lastSyncedAt: serializer.fromJson<int?>(json['last_synced_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'device_id': serializer.toJson<String>(deviceId),
      'drive_version': serializer.toJson<String?>(driveVersion),
      'drive_hash': serializer.toJson<String?>(driveHash),
      'newest_seen_at': serializer.toJson<int>(newestSeenAt),
      'last_synced_at': serializer.toJson<int?>(lastSyncedAt),
    };
  }

  Device copyWith({
    String? deviceId,
    Value<String?> driveVersion = const Value.absent(),
    Value<String?> driveHash = const Value.absent(),
    int? newestSeenAt,
    Value<int?> lastSyncedAt = const Value.absent(),
  }) => Device(
    deviceId: deviceId ?? this.deviceId,
    driveVersion: driveVersion.present ? driveVersion.value : this.driveVersion,
    driveHash: driveHash.present ? driveHash.value : this.driveHash,
    newestSeenAt: newestSeenAt ?? this.newestSeenAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  Device copyWithCompanion(DeviceCompanion data) {
    return Device(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      driveVersion: data.driveVersion.present
          ? data.driveVersion.value
          : this.driveVersion,
      driveHash: data.driveHash.present ? data.driveHash.value : this.driveHash,
      newestSeenAt: data.newestSeenAt.present
          ? data.newestSeenAt.value
          : this.newestSeenAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('deviceId: $deviceId, ')
          ..write('driveVersion: $driveVersion, ')
          ..write('driveHash: $driveHash, ')
          ..write('newestSeenAt: $newestSeenAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    driveVersion,
    driveHash,
    newestSeenAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.deviceId == this.deviceId &&
          other.driveVersion == this.driveVersion &&
          other.driveHash == this.driveHash &&
          other.newestSeenAt == this.newestSeenAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class DeviceCompanion extends UpdateCompanion<Device> {
  final Value<String> deviceId;
  final Value<String?> driveVersion;
  final Value<String?> driveHash;
  final Value<int> newestSeenAt;
  final Value<int?> lastSyncedAt;
  final Value<int> rowid;
  const DeviceCompanion({
    this.deviceId = const Value.absent(),
    this.driveVersion = const Value.absent(),
    this.driveHash = const Value.absent(),
    this.newestSeenAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceCompanion.insert({
    required String deviceId,
    this.driveVersion = const Value.absent(),
    this.driveHash = const Value.absent(),
    this.newestSeenAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<Device> custom({
    Expression<String>? deviceId,
    Expression<String>? driveVersion,
    Expression<String>? driveHash,
    Expression<int>? newestSeenAt,
    Expression<int>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (driveVersion != null) 'drive_version': driveVersion,
      if (driveHash != null) 'drive_hash': driveHash,
      if (newestSeenAt != null) 'newest_seen_at': newestSeenAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceCompanion copyWith({
    Value<String>? deviceId,
    Value<String?>? driveVersion,
    Value<String?>? driveHash,
    Value<int>? newestSeenAt,
    Value<int?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return DeviceCompanion(
      deviceId: deviceId ?? this.deviceId,
      driveVersion: driveVersion ?? this.driveVersion,
      driveHash: driveHash ?? this.driveHash,
      newestSeenAt: newestSeenAt ?? this.newestSeenAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (driveVersion.present) {
      map['drive_version'] = Variable<String>(driveVersion.value);
    }
    if (driveHash.present) {
      map['drive_hash'] = Variable<String>(driveHash.value);
    }
    if (newestSeenAt.present) {
      map['newest_seen_at'] = Variable<int>(newestSeenAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('driveVersion: $driveVersion, ')
          ..write('driveHash: $driveHash, ')
          ..write('newestSeenAt: $newestSeenAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RecordDatabase extends GeneratedDatabase {
  _$RecordDatabase(QueryExecutor e) : super(e);
  $RecordDatabaseManager get managers => $RecordDatabaseManager(this);
  late final EntryTable entry = EntryTable(this);
  late final Index idxEntryStatus = Index(
    'idx_entry_status',
    'CREATE INDEX idx_entry_status ON entry (status)',
  );
  late final Index idxEntryUpdated = Index(
    'idx_entry_updated',
    'CREATE INDEX idx_entry_updated ON entry (updated_at)',
  );
  late final EntryReferenceTable entryReference = EntryReferenceTable(this);
  late final Index idxReferenceLookup = Index(
    'idx_reference_lookup',
    'CREATE INDEX idx_reference_lookup ON entry_reference (provider, provider_id)',
  );
  late final MatchDeclineTable matchDecline = MatchDeclineTable(this);
  late final CompletionTable completion = CompletionTable(this);
  late final Index idxCompletionDate = Index(
    'idx_completion_date',
    'CREATE INDEX idx_completion_date ON completion (completed_at)',
  );
  late final AlertTable alert = AlertTable(this);
  late final EntryAliasTable entryAlias = EntryAliasTable(this);
  late final DeletionTable deletion = DeletionTable(this);
  late final SettingTable setting = SettingTable(this);
  late final DeviceTable device = DeviceTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entry,
    idxEntryStatus,
    idxEntryUpdated,
    entryReference,
    idxReferenceLookup,
    matchDecline,
    completion,
    idxCompletionDate,
    alert,
    entryAlias,
    deletion,
    setting,
    device,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_reference', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('match_decline', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $EntryTableCreateCompanionBuilder = EntryCompanion Function({
  required String entryId,
  Value<String?> name,
  required String status,
  Value<int> episodesWatched,
  Value<int?> score,
  Value<String?> notes,
  Value<int?> planRank,
  required int addedAt,
  Value<int?> startedAt,
  required int progressChangedAt,
  Value<int> scoreChangedAt,
  Value<int> notesChangedAt,
  Value<int> linkChangedAt,
  Value<int> rowid,
});
typedef $EntryTableUpdateCompanionBuilder = EntryCompanion Function({
  Value<String> entryId,
  Value<String?> name,
  Value<String> status,
  Value<int> episodesWatched,
  Value<int?> score,
  Value<String?> notes,
  Value<int?> planRank,
  Value<int> addedAt,
  Value<int?> startedAt,
  Value<int> progressChangedAt,
  Value<int> scoreChangedAt,
  Value<int> notesChangedAt,
  Value<int> linkChangedAt,
  Value<int> rowid,
});

final class $EntryTableReferences
    extends BaseReferences<_$RecordDatabase, EntryTable, Entry> {
  $EntryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<EntryReferenceTable, List<EntryReference>>
  _entryReferenceRefsTable(_$RecordDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.entryReference,
        aliasName: 'entry__entry_id__entry_reference__entry_id',
      );

  $EntryReferenceTableProcessedTableManager get entryReferenceRefs {
    final manager = $EntryReferenceTableTableManager($_db, $_db.entryReference)
        .filter(
          (f) => f.entryId.entryId.sqlEquals($_itemColumn<String>('entry_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_entryReferenceRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<MatchDeclineTable, List<MatchDecline>>
  _matchDeclineRefsTable(_$RecordDatabase db) => MultiTypedResultKey.fromTable(
    db.matchDecline,
    aliasName: 'entry__entry_id__match_decline__entry_id',
  );

  $MatchDeclineTableProcessedTableManager get matchDeclineRefs {
    final manager = $MatchDeclineTableTableManager($_db, $_db.matchDecline)
        .filter(
          (f) => f.entryId.entryId.sqlEquals($_itemColumn<String>('entry_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_matchDeclineRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $EntryTableFilterComposer extends Composer<_$RecordDatabase, EntryTable> {
  $EntryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodesWatched => $composableBuilder(
    column: $table.episodesWatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planRank => $composableBuilder(
    column: $table.planRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressChangedAt => $composableBuilder(
    column: $table.progressChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreChangedAt => $composableBuilder(
    column: $table.scoreChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notesChangedAt => $composableBuilder(
    column: $table.notesChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkChangedAt => $composableBuilder(
    column: $table.linkChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entryReferenceRefs(
    Expression<bool> Function($EntryReferenceTableFilterComposer f) f,
  ) {
    final $EntryReferenceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entryReference,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryReferenceTableFilterComposer(
            $db: $db,
            $table: $db.entryReference,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> matchDeclineRefs(
    Expression<bool> Function($MatchDeclineTableFilterComposer f) f,
  ) {
    final $MatchDeclineTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.matchDecline,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MatchDeclineTableFilterComposer(
            $db: $db,
            $table: $db.matchDecline,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $EntryTableOrderingComposer
    extends Composer<_$RecordDatabase, EntryTable> {
  $EntryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodesWatched => $composableBuilder(
    column: $table.episodesWatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planRank => $composableBuilder(
    column: $table.planRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressChangedAt => $composableBuilder(
    column: $table.progressChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreChangedAt => $composableBuilder(
    column: $table.scoreChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notesChangedAt => $composableBuilder(
    column: $table.notesChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkChangedAt => $composableBuilder(
    column: $table.linkChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $EntryTableAnnotationComposer
    extends Composer<_$RecordDatabase, EntryTable> {
  $EntryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get episodesWatched => $composableBuilder(
    column: $table.episodesWatched,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get planRank =>
      $composableBuilder(column: $table.planRank, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get progressChangedAt => $composableBuilder(
    column: $table.progressChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreChangedAt => $composableBuilder(
    column: $table.scoreChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notesChangedAt => $composableBuilder(
    column: $table.notesChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get linkChangedAt => $composableBuilder(
    column: $table.linkChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> entryReferenceRefs<T extends Object>(
    Expression<T> Function($EntryReferenceTableAnnotationComposer a) f,
  ) {
    final $EntryReferenceTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entryReference,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryReferenceTableAnnotationComposer(
            $db: $db,
            $table: $db.entryReference,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> matchDeclineRefs<T extends Object>(
    Expression<T> Function($MatchDeclineTableAnnotationComposer a) f,
  ) {
    final $MatchDeclineTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.matchDecline,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MatchDeclineTableAnnotationComposer(
            $db: $db,
            $table: $db.matchDecline,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $EntryTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          EntryTable,
          Entry,
          $EntryTableFilterComposer,
          $EntryTableOrderingComposer,
          $EntryTableAnnotationComposer,
          $EntryTableCreateCompanionBuilder,
          $EntryTableUpdateCompanionBuilder,
          (Entry, $EntryTableReferences),
          Entry,
          PrefetchHooks Function({
            bool entryReferenceRefs,
            bool matchDeclineRefs,
          })
        > {
  $EntryTableTableManager(_$RecordDatabase db, EntryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EntryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EntryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EntryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> episodesWatched = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> planRank = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int?> startedAt = const Value.absent(),
                Value<int> progressChangedAt = const Value.absent(),
                Value<int> scoreChangedAt = const Value.absent(),
                Value<int> notesChangedAt = const Value.absent(),
                Value<int> linkChangedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryCompanion(
                entryId: entryId,
                name: name,
                status: status,
                episodesWatched: episodesWatched,
                score: score,
                notes: notes,
                planRank: planRank,
                addedAt: addedAt,
                startedAt: startedAt,
                progressChangedAt: progressChangedAt,
                scoreChangedAt: scoreChangedAt,
                notesChangedAt: notesChangedAt,
                linkChangedAt: linkChangedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                Value<String?> name = const Value.absent(),
                required String status,
                Value<int> episodesWatched = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> planRank = const Value.absent(),
                required int addedAt,
                Value<int?> startedAt = const Value.absent(),
                required int progressChangedAt,
                Value<int> scoreChangedAt = const Value.absent(),
                Value<int> notesChangedAt = const Value.absent(),
                Value<int> linkChangedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryCompanion.insert(
                entryId: entryId,
                name: name,
                status: status,
                episodesWatched: episodesWatched,
                score: score,
                notes: notes,
                planRank: planRank,
                addedAt: addedAt,
                startedAt: startedAt,
                progressChangedAt: progressChangedAt,
                scoreChangedAt: scoreChangedAt,
                notesChangedAt: notesChangedAt,
                linkChangedAt: linkChangedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<EntryTable, Entry>(table),
                  $EntryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({entryReferenceRefs = false, matchDeclineRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entryReferenceRefs) db.entryReference,
                    if (matchDeclineRefs) db.matchDecline,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entryReferenceRefs)
                        await $_getPrefetchedDataByColumns<
                          Entry,
                          EntryTable,
                          EntryReference,
                          EntryReferenceTable
                        >(
                          currentTable: table,
                          referencedTable: $EntryTableReferences
                              ._entryReferenceRefsTable(db),
                          managerFromTypedResult: (p0) => $EntryTableReferences(
                            db,
                            table,
                            p0,
                          ).entryReferenceRefs,
                          currentColumn: 'entry_id',
                          referencedColumn: 'entry_id',
                          typedResults: items,
                        ),
                      if (matchDeclineRefs)
                        await $_getPrefetchedDataByColumns<
                          Entry,
                          EntryTable,
                          MatchDecline,
                          MatchDeclineTable
                        >(
                          currentTable: table,
                          referencedTable: $EntryTableReferences
                              ._matchDeclineRefsTable(db),
                          managerFromTypedResult: (p0) => $EntryTableReferences(
                            db,
                            table,
                            p0,
                          ).matchDeclineRefs,
                          currentColumn: 'entry_id',
                          referencedColumn: 'entry_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $EntryTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      EntryTable,
      Entry,
      $EntryTableFilterComposer,
      $EntryTableOrderingComposer,
      $EntryTableAnnotationComposer,
      $EntryTableCreateCompanionBuilder,
      $EntryTableUpdateCompanionBuilder,
      (Entry, $EntryTableReferences),
      Entry,
      PrefetchHooks Function({bool entryReferenceRefs, bool matchDeclineRefs})
    >;
typedef $EntryReferenceTableCreateCompanionBuilder =
    EntryReferenceCompanion Function({
      required String entryId,
      required String provider,
      required int providerId,
      Value<int> rowid,
    });
typedef $EntryReferenceTableUpdateCompanionBuilder =
    EntryReferenceCompanion Function({
      Value<String> entryId,
      Value<String> provider,
      Value<int> providerId,
      Value<int> rowid,
    });

final class $EntryReferenceTableReferences
    extends
        BaseReferences<_$RecordDatabase, EntryReferenceTable, EntryReference> {
  $EntryReferenceTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static EntryTable _entryIdTable(_$RecordDatabase db) =>
      db.entry.createAlias('entry_reference__entry_id__entry__entry_id');

  $EntryTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $EntryTableTableManager(
      $_db,
      $_db.entry,
    ).filter((f) => f.entryId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $EntryReferenceTableFilterComposer
    extends Composer<_$RecordDatabase, EntryReferenceTable> {
  $EntryReferenceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  $EntryTableFilterComposer get entryId {
    final $EntryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entry,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryTableFilterComposer(
            $db: $db,
            $table: $db.entry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntryReferenceTableOrderingComposer
    extends Composer<_$RecordDatabase, EntryReferenceTable> {
  $EntryReferenceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  $EntryTableOrderingComposer get entryId {
    final $EntryTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entry,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryTableOrderingComposer(
            $db: $db,
            $table: $db.entry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntryReferenceTableAnnotationComposer
    extends Composer<_$RecordDatabase, EntryReferenceTable> {
  $EntryReferenceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  $EntryTableAnnotationComposer get entryId {
    final $EntryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entry,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryTableAnnotationComposer(
            $db: $db,
            $table: $db.entry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntryReferenceTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          EntryReferenceTable,
          EntryReference,
          $EntryReferenceTableFilterComposer,
          $EntryReferenceTableOrderingComposer,
          $EntryReferenceTableAnnotationComposer,
          $EntryReferenceTableCreateCompanionBuilder,
          $EntryReferenceTableUpdateCompanionBuilder,
          (EntryReference, $EntryReferenceTableReferences),
          EntryReference,
          PrefetchHooks Function({bool entryId})
        > {
  $EntryReferenceTableTableManager(
    _$RecordDatabase db,
    EntryReferenceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EntryReferenceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EntryReferenceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EntryReferenceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryReferenceCompanion(
                entryId: entryId,
                provider: provider,
                providerId: providerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String provider,
                required int providerId,
                Value<int> rowid = const Value.absent(),
              }) => EntryReferenceCompanion.insert(
                entryId: entryId,
                provider: provider,
                providerId: providerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<EntryReferenceTable, EntryReference>(table),
                  $EntryReferenceTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $EntryReferenceTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $EntryReferenceTableReferences
                            ._entryIdTable(db)
                            .entryId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $EntryReferenceTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      EntryReferenceTable,
      EntryReference,
      $EntryReferenceTableFilterComposer,
      $EntryReferenceTableOrderingComposer,
      $EntryReferenceTableAnnotationComposer,
      $EntryReferenceTableCreateCompanionBuilder,
      $EntryReferenceTableUpdateCompanionBuilder,
      (EntryReference, $EntryReferenceTableReferences),
      EntryReference,
      PrefetchHooks Function({bool entryId})
    >;
typedef $MatchDeclineTableCreateCompanionBuilder =
    MatchDeclineCompanion Function({
      required String entryId,
      required String provider,
      required int providerId,
      required int declinedAt,
      Value<int> rowid,
    });
typedef $MatchDeclineTableUpdateCompanionBuilder =
    MatchDeclineCompanion Function({
      Value<String> entryId,
      Value<String> provider,
      Value<int> providerId,
      Value<int> declinedAt,
      Value<int> rowid,
    });

final class $MatchDeclineTableReferences
    extends BaseReferences<_$RecordDatabase, MatchDeclineTable, MatchDecline> {
  $MatchDeclineTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static EntryTable _entryIdTable(_$RecordDatabase db) =>
      db.entry.createAlias('match_decline__entry_id__entry__entry_id');

  $EntryTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $EntryTableTableManager(
      $_db,
      $_db.entry,
    ).filter((f) => f.entryId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $MatchDeclineTableFilterComposer
    extends Composer<_$RecordDatabase, MatchDeclineTable> {
  $MatchDeclineTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get declinedAt => $composableBuilder(
    column: $table.declinedAt,
    builder: (column) => ColumnFilters(column),
  );

  $EntryTableFilterComposer get entryId {
    final $EntryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entry,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryTableFilterComposer(
            $db: $db,
            $table: $db.entry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MatchDeclineTableOrderingComposer
    extends Composer<_$RecordDatabase, MatchDeclineTable> {
  $MatchDeclineTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get declinedAt => $composableBuilder(
    column: $table.declinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $EntryTableOrderingComposer get entryId {
    final $EntryTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entry,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryTableOrderingComposer(
            $db: $db,
            $table: $db.entry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MatchDeclineTableAnnotationComposer
    extends Composer<_$RecordDatabase, MatchDeclineTable> {
  $MatchDeclineTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get declinedAt => $composableBuilder(
    column: $table.declinedAt,
    builder: (column) => column,
  );

  $EntryTableAnnotationComposer get entryId {
    final $EntryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entry,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryTableAnnotationComposer(
            $db: $db,
            $table: $db.entry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MatchDeclineTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          MatchDeclineTable,
          MatchDecline,
          $MatchDeclineTableFilterComposer,
          $MatchDeclineTableOrderingComposer,
          $MatchDeclineTableAnnotationComposer,
          $MatchDeclineTableCreateCompanionBuilder,
          $MatchDeclineTableUpdateCompanionBuilder,
          (MatchDecline, $MatchDeclineTableReferences),
          MatchDecline,
          PrefetchHooks Function({bool entryId})
        > {
  $MatchDeclineTableTableManager(_$RecordDatabase db, MatchDeclineTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MatchDeclineTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MatchDeclineTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MatchDeclineTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> declinedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchDeclineCompanion(
                entryId: entryId,
                provider: provider,
                providerId: providerId,
                declinedAt: declinedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String provider,
                required int providerId,
                required int declinedAt,
                Value<int> rowid = const Value.absent(),
              }) => MatchDeclineCompanion.insert(
                entryId: entryId,
                provider: provider,
                providerId: providerId,
                declinedAt: declinedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MatchDeclineTable, MatchDecline>(table),
                  $MatchDeclineTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $MatchDeclineTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $MatchDeclineTableReferences
                            ._entryIdTable(db)
                            .entryId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $MatchDeclineTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      MatchDeclineTable,
      MatchDecline,
      $MatchDeclineTableFilterComposer,
      $MatchDeclineTableOrderingComposer,
      $MatchDeclineTableAnnotationComposer,
      $MatchDeclineTableCreateCompanionBuilder,
      $MatchDeclineTableUpdateCompanionBuilder,
      (MatchDecline, $MatchDeclineTableReferences),
      MatchDecline,
      PrefetchHooks Function({bool entryId})
    >;
typedef $CompletionTableCreateCompanionBuilder = CompletionCompanion Function({
  required String entryId,
  required int watchNumber,
  required int completedAt,
  Value<int> episodesWatched,
  Value<int?> minutesPerEpisode,
  Value<bool> isEstimated,
  Value<String?> name,
  Value<int> rowid,
});
typedef $CompletionTableUpdateCompanionBuilder = CompletionCompanion Function({
  Value<String> entryId,
  Value<int> watchNumber,
  Value<int> completedAt,
  Value<int> episodesWatched,
  Value<int?> minutesPerEpisode,
  Value<bool> isEstimated,
  Value<String?> name,
  Value<int> rowid,
});

class $CompletionTableFilterComposer
    extends Composer<_$RecordDatabase, CompletionTable> {
  $CompletionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get watchNumber => $composableBuilder(
    column: $table.watchNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodesWatched => $composableBuilder(
    column: $table.episodesWatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesPerEpisode => $composableBuilder(
    column: $table.minutesPerEpisode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $CompletionTableOrderingComposer
    extends Composer<_$RecordDatabase, CompletionTable> {
  $CompletionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get watchNumber => $composableBuilder(
    column: $table.watchNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodesWatched => $composableBuilder(
    column: $table.episodesWatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesPerEpisode => $composableBuilder(
    column: $table.minutesPerEpisode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CompletionTableAnnotationComposer
    extends Composer<_$RecordDatabase, CompletionTable> {
  $CompletionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get watchNumber => $composableBuilder(
    column: $table.watchNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodesWatched => $composableBuilder(
    column: $table.episodesWatched,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minutesPerEpisode => $composableBuilder(
    column: $table.minutesPerEpisode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $CompletionTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          CompletionTable,
          Completion,
          $CompletionTableFilterComposer,
          $CompletionTableOrderingComposer,
          $CompletionTableAnnotationComposer,
          $CompletionTableCreateCompanionBuilder,
          $CompletionTableUpdateCompanionBuilder,
          (
            Completion,
            BaseReferences<_$RecordDatabase, CompletionTable, Completion>,
          ),
          Completion,
          PrefetchHooks Function()
        > {
  $CompletionTableTableManager(_$RecordDatabase db, CompletionTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CompletionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CompletionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CompletionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<int> watchNumber = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
                Value<int> episodesWatched = const Value.absent(),
                Value<int?> minutesPerEpisode = const Value.absent(),
                Value<bool> isEstimated = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionCompanion(
                entryId: entryId,
                watchNumber: watchNumber,
                completedAt: completedAt,
                episodesWatched: episodesWatched,
                minutesPerEpisode: minutesPerEpisode,
                isEstimated: isEstimated,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required int watchNumber,
                required int completedAt,
                Value<int> episodesWatched = const Value.absent(),
                Value<int?> minutesPerEpisode = const Value.absent(),
                Value<bool> isEstimated = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionCompanion.insert(
                entryId: entryId,
                watchNumber: watchNumber,
                completedAt: completedAt,
                episodesWatched: episodesWatched,
                minutesPerEpisode: minutesPerEpisode,
                isEstimated: isEstimated,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<CompletionTable, Completion>(table),
                  BaseReferences<_$RecordDatabase, CompletionTable, Completion>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CompletionTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      CompletionTable,
      Completion,
      $CompletionTableFilterComposer,
      $CompletionTableOrderingComposer,
      $CompletionTableAnnotationComposer,
      $CompletionTableCreateCompanionBuilder,
      $CompletionTableUpdateCompanionBuilder,
      (
        Completion,
        BaseReferences<_$RecordDatabase, CompletionTable, Completion>,
      ),
      Completion,
      PrefetchHooks Function()
    >;
typedef $AlertTableCreateCompanionBuilder = AlertCompanion Function({
  required String entryId,
  required String relatedProvider,
  required int relatedProviderId,
  required String type,
  Value<bool> seen,
  Value<bool> dismissed,
  required int createdAt,
  Value<int> rowid,
});
typedef $AlertTableUpdateCompanionBuilder = AlertCompanion Function({
  Value<String> entryId,
  Value<String> relatedProvider,
  Value<int> relatedProviderId,
  Value<String> type,
  Value<bool> seen,
  Value<bool> dismissed,
  Value<int> createdAt,
  Value<int> rowid,
});

class $AlertTableFilterComposer extends Composer<_$RecordDatabase, AlertTable> {
  $AlertTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedProvider => $composableBuilder(
    column: $table.relatedProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relatedProviderId => $composableBuilder(
    column: $table.relatedProviderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $AlertTableOrderingComposer
    extends Composer<_$RecordDatabase, AlertTable> {
  $AlertTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedProvider => $composableBuilder(
    column: $table.relatedProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relatedProviderId => $composableBuilder(
    column: $table.relatedProviderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AlertTableAnnotationComposer
    extends Composer<_$RecordDatabase, AlertTable> {
  $AlertTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get relatedProvider => $composableBuilder(
    column: $table.relatedProvider,
    builder: (column) => column,
  );

  GeneratedColumn<int> get relatedProviderId => $composableBuilder(
    column: $table.relatedProviderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);

  GeneratedColumn<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $AlertTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          AlertTable,
          Alert,
          $AlertTableFilterComposer,
          $AlertTableOrderingComposer,
          $AlertTableAnnotationComposer,
          $AlertTableCreateCompanionBuilder,
          $AlertTableUpdateCompanionBuilder,
          (Alert, BaseReferences<_$RecordDatabase, AlertTable, Alert>),
          Alert,
          PrefetchHooks Function()
        > {
  $AlertTableTableManager(_$RecordDatabase db, AlertTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AlertTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AlertTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AlertTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> relatedProvider = const Value.absent(),
                Value<int> relatedProviderId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> seen = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertCompanion(
                entryId: entryId,
                relatedProvider: relatedProvider,
                relatedProviderId: relatedProviderId,
                type: type,
                seen: seen,
                dismissed: dismissed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String relatedProvider,
                required int relatedProviderId,
                required String type,
                Value<bool> seen = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AlertCompanion.insert(
                entryId: entryId,
                relatedProvider: relatedProvider,
                relatedProviderId: relatedProviderId,
                type: type,
                seen: seen,
                dismissed: dismissed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AlertTable, Alert>(table),
                  BaseReferences<_$RecordDatabase, AlertTable, Alert>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AlertTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      AlertTable,
      Alert,
      $AlertTableFilterComposer,
      $AlertTableOrderingComposer,
      $AlertTableAnnotationComposer,
      $AlertTableCreateCompanionBuilder,
      $AlertTableUpdateCompanionBuilder,
      (Alert, BaseReferences<_$RecordDatabase, AlertTable, Alert>),
      Alert,
      PrefetchHooks Function()
    >;
typedef $EntryAliasTableCreateCompanionBuilder = EntryAliasCompanion Function({
  required String aliasId,
  required String entryId,
  Value<int> rowid,
});
typedef $EntryAliasTableUpdateCompanionBuilder = EntryAliasCompanion Function({
  Value<String> aliasId,
  Value<String> entryId,
  Value<int> rowid,
});

class $EntryAliasTableFilterComposer
    extends Composer<_$RecordDatabase, EntryAliasTable> {
  $EntryAliasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get aliasId => $composableBuilder(
    column: $table.aliasId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $EntryAliasTableOrderingComposer
    extends Composer<_$RecordDatabase, EntryAliasTable> {
  $EntryAliasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get aliasId => $composableBuilder(
    column: $table.aliasId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $EntryAliasTableAnnotationComposer
    extends Composer<_$RecordDatabase, EntryAliasTable> {
  $EntryAliasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get aliasId =>
      $composableBuilder(column: $table.aliasId, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);
}

class $EntryAliasTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          EntryAliasTable,
          EntryAlias,
          $EntryAliasTableFilterComposer,
          $EntryAliasTableOrderingComposer,
          $EntryAliasTableAnnotationComposer,
          $EntryAliasTableCreateCompanionBuilder,
          $EntryAliasTableUpdateCompanionBuilder,
          (
            EntryAlias,
            BaseReferences<_$RecordDatabase, EntryAliasTable, EntryAlias>,
          ),
          EntryAlias,
          PrefetchHooks Function()
        > {
  $EntryAliasTableTableManager(_$RecordDatabase db, EntryAliasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EntryAliasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EntryAliasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EntryAliasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> aliasId = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryAliasCompanion(
                aliasId: aliasId,
                entryId: entryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String aliasId,
                required String entryId,
                Value<int> rowid = const Value.absent(),
              }) => EntryAliasCompanion.insert(
                aliasId: aliasId,
                entryId: entryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<EntryAliasTable, EntryAlias>(table),
                  BaseReferences<_$RecordDatabase, EntryAliasTable, EntryAlias>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $EntryAliasTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      EntryAliasTable,
      EntryAlias,
      $EntryAliasTableFilterComposer,
      $EntryAliasTableOrderingComposer,
      $EntryAliasTableAnnotationComposer,
      $EntryAliasTableCreateCompanionBuilder,
      $EntryAliasTableUpdateCompanionBuilder,
      (
        EntryAlias,
        BaseReferences<_$RecordDatabase, EntryAliasTable, EntryAlias>,
      ),
      EntryAlias,
      PrefetchHooks Function()
    >;
typedef $DeletionTableCreateCompanionBuilder = DeletionCompanion Function({
  required String entryId,
  required int deletedAt,
  Value<int> rowid,
});
typedef $DeletionTableUpdateCompanionBuilder = DeletionCompanion Function({
  Value<String> entryId,
  Value<int> deletedAt,
  Value<int> rowid,
});

class $DeletionTableFilterComposer
    extends Composer<_$RecordDatabase, DeletionTable> {
  $DeletionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $DeletionTableOrderingComposer
    extends Composer<_$RecordDatabase, DeletionTable> {
  $DeletionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DeletionTableAnnotationComposer
    extends Composer<_$RecordDatabase, DeletionTable> {
  $DeletionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $DeletionTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          DeletionTable,
          Deletion,
          $DeletionTableFilterComposer,
          $DeletionTableOrderingComposer,
          $DeletionTableAnnotationComposer,
          $DeletionTableCreateCompanionBuilder,
          $DeletionTableUpdateCompanionBuilder,
          (Deletion, BaseReferences<_$RecordDatabase, DeletionTable, Deletion>),
          Deletion,
          PrefetchHooks Function()
        > {
  $DeletionTableTableManager(_$RecordDatabase db, DeletionTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DeletionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DeletionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DeletionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<int> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletionCompanion(
                entryId: entryId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required int deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeletionCompanion.insert(
                entryId: entryId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DeletionTable, Deletion>(table),
                  BaseReferences<_$RecordDatabase, DeletionTable, Deletion>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DeletionTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      DeletionTable,
      Deletion,
      $DeletionTableFilterComposer,
      $DeletionTableOrderingComposer,
      $DeletionTableAnnotationComposer,
      $DeletionTableCreateCompanionBuilder,
      $DeletionTableUpdateCompanionBuilder,
      (Deletion, BaseReferences<_$RecordDatabase, DeletionTable, Deletion>),
      Deletion,
      PrefetchHooks Function()
    >;
typedef $SettingTableCreateCompanionBuilder = SettingCompanion Function({
  required String key,
  required String value,
  Value<int> updatedAt,
  Value<int> rowid,
});
typedef $SettingTableUpdateCompanionBuilder = SettingCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $SettingTableFilterComposer
    extends Composer<_$RecordDatabase, SettingTable> {
  $SettingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SettingTableOrderingComposer
    extends Composer<_$RecordDatabase, SettingTable> {
  $SettingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SettingTableAnnotationComposer
    extends Composer<_$RecordDatabase, SettingTable> {
  $SettingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $SettingTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          SettingTable,
          Setting,
          $SettingTableFilterComposer,
          $SettingTableOrderingComposer,
          $SettingTableAnnotationComposer,
          $SettingTableCreateCompanionBuilder,
          $SettingTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$RecordDatabase, SettingTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $SettingTableTableManager(_$RecordDatabase db, SettingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SettingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SettingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SettingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SettingTable, Setting>(table),
                  BaseReferences<_$RecordDatabase, SettingTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SettingTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      SettingTable,
      Setting,
      $SettingTableFilterComposer,
      $SettingTableOrderingComposer,
      $SettingTableAnnotationComposer,
      $SettingTableCreateCompanionBuilder,
      $SettingTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$RecordDatabase, SettingTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $DeviceTableCreateCompanionBuilder = DeviceCompanion Function({
  required String deviceId,
  Value<String?> driveVersion,
  Value<String?> driveHash,
  Value<int> newestSeenAt,
  Value<int?> lastSyncedAt,
  Value<int> rowid,
});
typedef $DeviceTableUpdateCompanionBuilder = DeviceCompanion Function({
  Value<String> deviceId,
  Value<String?> driveVersion,
  Value<String?> driveHash,
  Value<int> newestSeenAt,
  Value<int?> lastSyncedAt,
  Value<int> rowid,
});

class $DeviceTableFilterComposer
    extends Composer<_$RecordDatabase, DeviceTable> {
  $DeviceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveVersion => $composableBuilder(
    column: $table.driveVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveHash => $composableBuilder(
    column: $table.driveHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newestSeenAt => $composableBuilder(
    column: $table.newestSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $DeviceTableOrderingComposer
    extends Composer<_$RecordDatabase, DeviceTable> {
  $DeviceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveVersion => $composableBuilder(
    column: $table.driveVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveHash => $composableBuilder(
    column: $table.driveHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newestSeenAt => $composableBuilder(
    column: $table.newestSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DeviceTableAnnotationComposer
    extends Composer<_$RecordDatabase, DeviceTable> {
  $DeviceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get driveVersion => $composableBuilder(
    column: $table.driveVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get driveHash =>
      $composableBuilder(column: $table.driveHash, builder: (column) => column);

  GeneratedColumn<int> get newestSeenAt => $composableBuilder(
    column: $table.newestSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $DeviceTableTableManager
    extends
        RootTableManager<
          _$RecordDatabase,
          DeviceTable,
          Device,
          $DeviceTableFilterComposer,
          $DeviceTableOrderingComposer,
          $DeviceTableAnnotationComposer,
          $DeviceTableCreateCompanionBuilder,
          $DeviceTableUpdateCompanionBuilder,
          (Device, BaseReferences<_$RecordDatabase, DeviceTable, Device>),
          Device,
          PrefetchHooks Function()
        > {
  $DeviceTableTableManager(_$RecordDatabase db, DeviceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DeviceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DeviceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DeviceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String?> driveVersion = const Value.absent(),
                Value<String?> driveHash = const Value.absent(),
                Value<int> newestSeenAt = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceCompanion(
                deviceId: deviceId,
                driveVersion: driveVersion,
                driveHash: driveHash,
                newestSeenAt: newestSeenAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                Value<String?> driveVersion = const Value.absent(),
                Value<String?> driveHash = const Value.absent(),
                Value<int> newestSeenAt = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceCompanion.insert(
                deviceId: deviceId,
                driveVersion: driveVersion,
                driveHash: driveHash,
                newestSeenAt: newestSeenAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DeviceTable, Device>(table),
                  BaseReferences<_$RecordDatabase, DeviceTable, Device>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DeviceTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordDatabase,
      DeviceTable,
      Device,
      $DeviceTableFilterComposer,
      $DeviceTableOrderingComposer,
      $DeviceTableAnnotationComposer,
      $DeviceTableCreateCompanionBuilder,
      $DeviceTableUpdateCompanionBuilder,
      (Device, BaseReferences<_$RecordDatabase, DeviceTable, Device>),
      Device,
      PrefetchHooks Function()
    >;

class $RecordDatabaseManager {
  final _$RecordDatabase _db;
  $RecordDatabaseManager(this._db);
  $EntryTableTableManager get entry => $EntryTableTableManager(_db, _db.entry);
  $EntryReferenceTableTableManager get entryReference =>
      $EntryReferenceTableTableManager(_db, _db.entryReference);
  $MatchDeclineTableTableManager get matchDecline =>
      $MatchDeclineTableTableManager(_db, _db.matchDecline);
  $CompletionTableTableManager get completion =>
      $CompletionTableTableManager(_db, _db.completion);
  $AlertTableTableManager get alert => $AlertTableTableManager(_db, _db.alert);
  $EntryAliasTableTableManager get entryAlias =>
      $EntryAliasTableTableManager(_db, _db.entryAlias);
  $DeletionTableTableManager get deletion =>
      $DeletionTableTableManager(_db, _db.deletion);
  $SettingTableTableManager get setting =>
      $SettingTableTableManager(_db, _db.setting);
  $DeviceTableTableManager get device =>
      $DeviceTableTableManager(_db, _db.device);
}
