// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'details_database.dart';

// ignore_for_file: type=lint
class DetailTable extends Table with TableInfo<DetailTable, Detail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DetailTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isFullMeta = const VerificationMeta('isFull');
  late final GeneratedColumn<bool> isFull = GeneratedColumn<bool>(
    'is_full',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('json_extract(json, \'\$.title\')'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'GENERATED ALWAYS AS (json_extract(json, \'\$.title\')) VIRTUAL',
  );
  static const VerificationMeta _titleEnglishMeta = const VerificationMeta(
    'titleEnglish',
  );
  late final GeneratedColumn<String> titleEnglish = GeneratedColumn<String>(
    'title_english',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression(
        'NULLIF(json_extract(json, \'\$.alternative_titles.en\'), \'\')',
      ),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (NULLIF(json_extract(json, \'\$.alternative_titles.en\'), \'\')) VIRTUAL',
  );
  static const VerificationMeta _titleJapaneseMeta = const VerificationMeta(
    'titleJapanese',
  );
  late final GeneratedColumn<String> titleJapanese = GeneratedColumn<String>(
    'title_japanese',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression(
        'NULLIF(json_extract(json, \'\$.alternative_titles.ja\'), \'\')',
      ),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (NULLIF(json_extract(json, \'\$.alternative_titles.ja\'), \'\')) VIRTUAL',
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('json_extract(json, \'\$.media_type\')'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'GENERATED ALWAYS AS (json_extract(json, \'\$.media_type\')) VIRTUAL',
  );
  static const VerificationMeta _airingStatusMeta = const VerificationMeta(
    'airingStatus',
  );
  late final GeneratedColumn<String> airingStatus = GeneratedColumn<String>(
    'airing_status',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('json_extract(json, \'\$.status\')'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'GENERATED ALWAYS AS (json_extract(json, \'\$.status\')) VIRTUAL',
  );
  static const VerificationMeta _episodesMeta = const VerificationMeta(
    'episodes',
  );
  late final GeneratedColumn<int> episodes = GeneratedColumn<int>(
    'episodes',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression(
        'NULLIF(json_extract(json, \'\$.num_episodes\'), 0)',
      ),
      false,
    ),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (NULLIF(json_extract(json, \'\$.num_episodes\'), 0)) VIRTUAL',
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('json_extract(json, \'\$.start_date\')'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'GENERATED ALWAYS AS (json_extract(json, \'\$.start_date\')) VIRTUAL',
  );
  static const VerificationMeta _coverMediumUrlMeta = const VerificationMeta(
    'coverMediumUrl',
  );
  late final GeneratedColumn<String> coverMediumUrl = GeneratedColumn<String>(
    'cover_medium_url',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('json_extract(json, \'\$.main_picture.medium\')'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (json_extract(json, \'\$.main_picture.medium\')) VIRTUAL',
  );
  static const VerificationMeta _coverLargeUrlMeta = const VerificationMeta(
    'coverLargeUrl',
  );
  late final GeneratedColumn<String> coverLargeUrl = GeneratedColumn<String>(
    'cover_large_url',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('json_extract(json, \'\$.main_picture.large\')'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (json_extract(json, \'\$.main_picture.large\')) VIRTUAL',
  );
  static const VerificationMeta _nsfwMeta = const VerificationMeta('nsfw');
  late final GeneratedColumn<String> nsfw = GeneratedColumn<String>(
    'nsfw',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('json_extract(json, \'\$.nsfw\')'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'GENERATED ALWAYS AS (json_extract(json, \'\$.nsfw\')) VIRTUAL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    provider,
    providerId,
    fetchedAt,
    json,
    isFull,
    title,
    titleEnglish,
    titleJapanese,
    mediaType,
    airingStatus,
    episodes,
    startDate,
    coverMediumUrl,
    coverLargeUrl,
    nsfw,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detail';
  @override
  VerificationContext validateIntegrity(
    Insertable<Detail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('is_full')) {
      context.handle(
        _isFullMeta,
        isFull.isAcceptableOrUnknown(data['is_full']!, _isFullMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('title_english')) {
      context.handle(
        _titleEnglishMeta,
        titleEnglish.isAcceptableOrUnknown(
          data['title_english']!,
          _titleEnglishMeta,
        ),
      );
    }
    if (data.containsKey('title_japanese')) {
      context.handle(
        _titleJapaneseMeta,
        titleJapanese.isAcceptableOrUnknown(
          data['title_japanese']!,
          _titleJapaneseMeta,
        ),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('airing_status')) {
      context.handle(
        _airingStatusMeta,
        airingStatus.isAcceptableOrUnknown(
          data['airing_status']!,
          _airingStatusMeta,
        ),
      );
    }
    if (data.containsKey('episodes')) {
      context.handle(
        _episodesMeta,
        episodes.isAcceptableOrUnknown(data['episodes']!, _episodesMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('cover_medium_url')) {
      context.handle(
        _coverMediumUrlMeta,
        coverMediumUrl.isAcceptableOrUnknown(
          data['cover_medium_url']!,
          _coverMediumUrlMeta,
        ),
      );
    }
    if (data.containsKey('cover_large_url')) {
      context.handle(
        _coverLargeUrlMeta,
        coverLargeUrl.isAcceptableOrUnknown(
          data['cover_large_url']!,
          _coverLargeUrlMeta,
        ),
      );
    }
    if (data.containsKey('nsfw')) {
      context.handle(
        _nsfwMeta,
        nsfw.isAcceptableOrUnknown(data['nsfw']!, _nsfwMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {provider, providerId};
  @override
  Detail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Detail(
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      isFull: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_full'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      titleEnglish: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_english'],
      ),
      titleJapanese: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_japanese'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      ),
      airingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}airing_status'],
      ),
      episodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episodes'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      coverMediumUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_medium_url'],
      ),
      coverLargeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_large_url'],
      ),
      nsfw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nsfw'],
      ),
    );
  }

  @override
  DetailTable createAlias(String alias) {
    return DetailTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(provider, provider_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Detail extends DataClass implements Insertable<Detail> {
  final String provider;
  final int providerId;
  final int fetchedAt;
  final String json;

  /// the trickle fetches a short field list; a detail page fetches all of them
  final bool isFull;
  final String? title;
  final String? titleEnglish;
  final String? titleJapanese;
  final String? mediaType;
  final String? airingStatus;

  /// mal sends 0 when the count is not known yet
  final int? episodes;
  final String? startDate;
  final String? coverMediumUrl;
  final String? coverLargeUrl;
  final String? nsfw;
  const Detail({
    required this.provider,
    required this.providerId,
    required this.fetchedAt,
    required this.json,
    required this.isFull,
    this.title,
    this.titleEnglish,
    this.titleJapanese,
    this.mediaType,
    this.airingStatus,
    this.episodes,
    this.startDate,
    this.coverMediumUrl,
    this.coverLargeUrl,
    this.nsfw,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['json'] = Variable<String>(json);
    map['is_full'] = Variable<bool>(isFull);
    return map;
  }

  DetailCompanion toCompanion(bool nullToAbsent) {
    return DetailCompanion(
      provider: Value(provider),
      providerId: Value(providerId),
      fetchedAt: Value(fetchedAt),
      json: Value(json),
      isFull: Value(isFull),
    );
  }

  factory Detail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Detail(
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
      fetchedAt: serializer.fromJson<int>(json['fetched_at']),
      json: serializer.fromJson<String>(json['json']),
      isFull: serializer.fromJson<bool>(json['is_full']),
      title: serializer.fromJson<String?>(json['title']),
      titleEnglish: serializer.fromJson<String?>(json['title_english']),
      titleJapanese: serializer.fromJson<String?>(json['title_japanese']),
      mediaType: serializer.fromJson<String?>(json['media_type']),
      airingStatus: serializer.fromJson<String?>(json['airing_status']),
      episodes: serializer.fromJson<int?>(json['episodes']),
      startDate: serializer.fromJson<String?>(json['start_date']),
      coverMediumUrl: serializer.fromJson<String?>(json['cover_medium_url']),
      coverLargeUrl: serializer.fromJson<String?>(json['cover_large_url']),
      nsfw: serializer.fromJson<String?>(json['nsfw']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
      'fetched_at': serializer.toJson<int>(fetchedAt),
      'json': serializer.toJson<String>(json),
      'is_full': serializer.toJson<bool>(isFull),
      'title': serializer.toJson<String?>(title),
      'title_english': serializer.toJson<String?>(titleEnglish),
      'title_japanese': serializer.toJson<String?>(titleJapanese),
      'media_type': serializer.toJson<String?>(mediaType),
      'airing_status': serializer.toJson<String?>(airingStatus),
      'episodes': serializer.toJson<int?>(episodes),
      'start_date': serializer.toJson<String?>(startDate),
      'cover_medium_url': serializer.toJson<String?>(coverMediumUrl),
      'cover_large_url': serializer.toJson<String?>(coverLargeUrl),
      'nsfw': serializer.toJson<String?>(nsfw),
    };
  }

  Detail copyWith({
    String? provider,
    int? providerId,
    int? fetchedAt,
    String? json,
    bool? isFull,
    Value<String?> title = const Value.absent(),
    Value<String?> titleEnglish = const Value.absent(),
    Value<String?> titleJapanese = const Value.absent(),
    Value<String?> mediaType = const Value.absent(),
    Value<String?> airingStatus = const Value.absent(),
    Value<int?> episodes = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> coverMediumUrl = const Value.absent(),
    Value<String?> coverLargeUrl = const Value.absent(),
    Value<String?> nsfw = const Value.absent(),
  }) => Detail(
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    json: json ?? this.json,
    isFull: isFull ?? this.isFull,
    title: title.present ? title.value : this.title,
    titleEnglish: titleEnglish.present ? titleEnglish.value : this.titleEnglish,
    titleJapanese: titleJapanese.present
        ? titleJapanese.value
        : this.titleJapanese,
    mediaType: mediaType.present ? mediaType.value : this.mediaType,
    airingStatus: airingStatus.present ? airingStatus.value : this.airingStatus,
    episodes: episodes.present ? episodes.value : this.episodes,
    startDate: startDate.present ? startDate.value : this.startDate,
    coverMediumUrl: coverMediumUrl.present
        ? coverMediumUrl.value
        : this.coverMediumUrl,
    coverLargeUrl: coverLargeUrl.present
        ? coverLargeUrl.value
        : this.coverLargeUrl,
    nsfw: nsfw.present ? nsfw.value : this.nsfw,
  );
  @override
  String toString() {
    return (StringBuffer('Detail(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('json: $json, ')
          ..write('isFull: $isFull, ')
          ..write('title: $title, ')
          ..write('titleEnglish: $titleEnglish, ')
          ..write('titleJapanese: $titleJapanese, ')
          ..write('mediaType: $mediaType, ')
          ..write('airingStatus: $airingStatus, ')
          ..write('episodes: $episodes, ')
          ..write('startDate: $startDate, ')
          ..write('coverMediumUrl: $coverMediumUrl, ')
          ..write('coverLargeUrl: $coverLargeUrl, ')
          ..write('nsfw: $nsfw')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    provider,
    providerId,
    fetchedAt,
    json,
    isFull,
    title,
    titleEnglish,
    titleJapanese,
    mediaType,
    airingStatus,
    episodes,
    startDate,
    coverMediumUrl,
    coverLargeUrl,
    nsfw,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Detail &&
          other.provider == this.provider &&
          other.providerId == this.providerId &&
          other.fetchedAt == this.fetchedAt &&
          other.json == this.json &&
          other.isFull == this.isFull &&
          other.title == this.title &&
          other.titleEnglish == this.titleEnglish &&
          other.titleJapanese == this.titleJapanese &&
          other.mediaType == this.mediaType &&
          other.airingStatus == this.airingStatus &&
          other.episodes == this.episodes &&
          other.startDate == this.startDate &&
          other.coverMediumUrl == this.coverMediumUrl &&
          other.coverLargeUrl == this.coverLargeUrl &&
          other.nsfw == this.nsfw);
}

class DetailCompanion extends UpdateCompanion<Detail> {
  final Value<String> provider;
  final Value<int> providerId;
  final Value<int> fetchedAt;
  final Value<String> json;
  final Value<bool> isFull;
  final Value<int> rowid;
  const DetailCompanion({
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.json = const Value.absent(),
    this.isFull = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DetailCompanion.insert({
    required String provider,
    required int providerId,
    required int fetchedAt,
    required String json,
    this.isFull = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : provider = Value(provider),
       providerId = Value(providerId),
       fetchedAt = Value(fetchedAt),
       json = Value(json);
  static Insertable<Detail> custom({
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<int>? fetchedAt,
    Expression<String>? json,
    Expression<bool>? isFull,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (json != null) 'json': json,
      if (isFull != null) 'is_full': isFull,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DetailCompanion copyWith({
    Value<String>? provider,
    Value<int>? providerId,
    Value<int>? fetchedAt,
    Value<String>? json,
    Value<bool>? isFull,
    Value<int>? rowid,
  }) {
    return DetailCompanion(
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      json: json ?? this.json,
      isFull: isFull ?? this.isFull,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (isFull.present) {
      map['is_full'] = Variable<bool>(isFull.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetailCompanion(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('json: $json, ')
          ..write('isFull: $isFull, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FranchiseLinkTable extends Table
    with TableInfo<FranchiseLinkTable, FranchiseLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FranchiseLinkTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _franchiseProviderMeta = const VerificationMeta(
    'franchiseProvider',
  );
  late final GeneratedColumn<String> franchiseProvider =
      GeneratedColumn<String>(
        'franchise_provider',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _franchiseProviderIdMeta =
      const VerificationMeta('franchiseProviderId');
  late final GeneratedColumn<int> franchiseProviderId = GeneratedColumn<int>(
    'franchise_provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isExtraMeta = const VerificationMeta(
    'isExtra',
  );
  late final GeneratedColumn<bool> isExtra = GeneratedColumn<bool>(
    'is_extra',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _isPlaceholderMeta = const VerificationMeta(
    'isPlaceholder',
  );
  late final GeneratedColumn<bool> isPlaceholder = GeneratedColumn<bool>(
    'is_placeholder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    franchiseProvider,
    franchiseProviderId,
    isExtra,
    isPlaceholder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'franchise_link';
  @override
  VerificationContext validateIntegrity(
    Insertable<FranchiseLink> instance, {
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
    if (data.containsKey('franchise_provider')) {
      context.handle(
        _franchiseProviderMeta,
        franchiseProvider.isAcceptableOrUnknown(
          data['franchise_provider']!,
          _franchiseProviderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_franchiseProviderMeta);
    }
    if (data.containsKey('franchise_provider_id')) {
      context.handle(
        _franchiseProviderIdMeta,
        franchiseProviderId.isAcceptableOrUnknown(
          data['franchise_provider_id']!,
          _franchiseProviderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_franchiseProviderIdMeta);
    }
    if (data.containsKey('is_extra')) {
      context.handle(
        _isExtraMeta,
        isExtra.isAcceptableOrUnknown(data['is_extra']!, _isExtraMeta),
      );
    }
    if (data.containsKey('is_placeholder')) {
      context.handle(
        _isPlaceholderMeta,
        isPlaceholder.isAcceptableOrUnknown(
          data['is_placeholder']!,
          _isPlaceholderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  FranchiseLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FranchiseLink(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      franchiseProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}franchise_provider'],
      )!,
      franchiseProviderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}franchise_provider_id'],
      )!,
      isExtra: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_extra'],
      )!,
      isPlaceholder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_placeholder'],
      )!,
    );
  }

  @override
  FranchiseLinkTable createAlias(String alias) {
    return FranchiseLinkTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FranchiseLink extends DataClass implements Insertable<FranchiseLink> {
  final String entryId;
  final String franchiseProvider;
  final int franchiseProviderId;
  final bool isExtra;
  final bool isPlaceholder;
  const FranchiseLink({
    required this.entryId,
    required this.franchiseProvider,
    required this.franchiseProviderId,
    required this.isExtra,
    required this.isPlaceholder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['franchise_provider'] = Variable<String>(franchiseProvider);
    map['franchise_provider_id'] = Variable<int>(franchiseProviderId);
    map['is_extra'] = Variable<bool>(isExtra);
    map['is_placeholder'] = Variable<bool>(isPlaceholder);
    return map;
  }

  FranchiseLinkCompanion toCompanion(bool nullToAbsent) {
    return FranchiseLinkCompanion(
      entryId: Value(entryId),
      franchiseProvider: Value(franchiseProvider),
      franchiseProviderId: Value(franchiseProviderId),
      isExtra: Value(isExtra),
      isPlaceholder: Value(isPlaceholder),
    );
  }

  factory FranchiseLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FranchiseLink(
      entryId: serializer.fromJson<String>(json['entry_id']),
      franchiseProvider: serializer.fromJson<String>(
        json['franchise_provider'],
      ),
      franchiseProviderId: serializer.fromJson<int>(
        json['franchise_provider_id'],
      ),
      isExtra: serializer.fromJson<bool>(json['is_extra']),
      isPlaceholder: serializer.fromJson<bool>(json['is_placeholder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'franchise_provider': serializer.toJson<String>(franchiseProvider),
      'franchise_provider_id': serializer.toJson<int>(franchiseProviderId),
      'is_extra': serializer.toJson<bool>(isExtra),
      'is_placeholder': serializer.toJson<bool>(isPlaceholder),
    };
  }

  FranchiseLink copyWith({
    String? entryId,
    String? franchiseProvider,
    int? franchiseProviderId,
    bool? isExtra,
    bool? isPlaceholder,
  }) => FranchiseLink(
    entryId: entryId ?? this.entryId,
    franchiseProvider: franchiseProvider ?? this.franchiseProvider,
    franchiseProviderId: franchiseProviderId ?? this.franchiseProviderId,
    isExtra: isExtra ?? this.isExtra,
    isPlaceholder: isPlaceholder ?? this.isPlaceholder,
  );
  FranchiseLink copyWithCompanion(FranchiseLinkCompanion data) {
    return FranchiseLink(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      franchiseProvider: data.franchiseProvider.present
          ? data.franchiseProvider.value
          : this.franchiseProvider,
      franchiseProviderId: data.franchiseProviderId.present
          ? data.franchiseProviderId.value
          : this.franchiseProviderId,
      isExtra: data.isExtra.present ? data.isExtra.value : this.isExtra,
      isPlaceholder: data.isPlaceholder.present
          ? data.isPlaceholder.value
          : this.isPlaceholder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FranchiseLink(')
          ..write('entryId: $entryId, ')
          ..write('franchiseProvider: $franchiseProvider, ')
          ..write('franchiseProviderId: $franchiseProviderId, ')
          ..write('isExtra: $isExtra, ')
          ..write('isPlaceholder: $isPlaceholder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    franchiseProvider,
    franchiseProviderId,
    isExtra,
    isPlaceholder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FranchiseLink &&
          other.entryId == this.entryId &&
          other.franchiseProvider == this.franchiseProvider &&
          other.franchiseProviderId == this.franchiseProviderId &&
          other.isExtra == this.isExtra &&
          other.isPlaceholder == this.isPlaceholder);
}

class FranchiseLinkCompanion extends UpdateCompanion<FranchiseLink> {
  final Value<String> entryId;
  final Value<String> franchiseProvider;
  final Value<int> franchiseProviderId;
  final Value<bool> isExtra;
  final Value<bool> isPlaceholder;
  final Value<int> rowid;
  const FranchiseLinkCompanion({
    this.entryId = const Value.absent(),
    this.franchiseProvider = const Value.absent(),
    this.franchiseProviderId = const Value.absent(),
    this.isExtra = const Value.absent(),
    this.isPlaceholder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FranchiseLinkCompanion.insert({
    required String entryId,
    required String franchiseProvider,
    required int franchiseProviderId,
    this.isExtra = const Value.absent(),
    this.isPlaceholder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       franchiseProvider = Value(franchiseProvider),
       franchiseProviderId = Value(franchiseProviderId);
  static Insertable<FranchiseLink> custom({
    Expression<String>? entryId,
    Expression<String>? franchiseProvider,
    Expression<int>? franchiseProviderId,
    Expression<bool>? isExtra,
    Expression<bool>? isPlaceholder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (franchiseProvider != null) 'franchise_provider': franchiseProvider,
      if (franchiseProviderId != null)
        'franchise_provider_id': franchiseProviderId,
      if (isExtra != null) 'is_extra': isExtra,
      if (isPlaceholder != null) 'is_placeholder': isPlaceholder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FranchiseLinkCompanion copyWith({
    Value<String>? entryId,
    Value<String>? franchiseProvider,
    Value<int>? franchiseProviderId,
    Value<bool>? isExtra,
    Value<bool>? isPlaceholder,
    Value<int>? rowid,
  }) {
    return FranchiseLinkCompanion(
      entryId: entryId ?? this.entryId,
      franchiseProvider: franchiseProvider ?? this.franchiseProvider,
      franchiseProviderId: franchiseProviderId ?? this.franchiseProviderId,
      isExtra: isExtra ?? this.isExtra,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (franchiseProvider.present) {
      map['franchise_provider'] = Variable<String>(franchiseProvider.value);
    }
    if (franchiseProviderId.present) {
      map['franchise_provider_id'] = Variable<int>(franchiseProviderId.value);
    }
    if (isExtra.present) {
      map['is_extra'] = Variable<bool>(isExtra.value);
    }
    if (isPlaceholder.present) {
      map['is_placeholder'] = Variable<bool>(isPlaceholder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FranchiseLinkCompanion(')
          ..write('entryId: $entryId, ')
          ..write('franchiseProvider: $franchiseProvider, ')
          ..write('franchiseProviderId: $franchiseProviderId, ')
          ..write('isExtra: $isExtra, ')
          ..write('isPlaceholder: $isPlaceholder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class GonePageTable extends Table with TableInfo<GonePageTable, GonePage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GonePageTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  late final GeneratedColumn<int> checkedAt = GeneratedColumn<int>(
    'checked_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [provider, providerId, checkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gone_page';
  @override
  VerificationContext validateIntegrity(
    Insertable<GonePage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_checkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {provider, providerId};
  @override
  GonePage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GonePage(
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}checked_at'],
      )!,
    );
  }

  @override
  GonePageTable createAlias(String alias) {
    return GonePageTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(provider, provider_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class GonePage extends DataClass implements Insertable<GonePage> {
  final String provider;
  final int providerId;
  final int checkedAt;
  const GonePage({
    required this.provider,
    required this.providerId,
    required this.checkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['checked_at'] = Variable<int>(checkedAt);
    return map;
  }

  GonePageCompanion toCompanion(bool nullToAbsent) {
    return GonePageCompanion(
      provider: Value(provider),
      providerId: Value(providerId),
      checkedAt: Value(checkedAt),
    );
  }

  factory GonePage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GonePage(
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
      checkedAt: serializer.fromJson<int>(json['checked_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
      'checked_at': serializer.toJson<int>(checkedAt),
    };
  }

  GonePage copyWith({String? provider, int? providerId, int? checkedAt}) =>
      GonePage(
        provider: provider ?? this.provider,
        providerId: providerId ?? this.providerId,
        checkedAt: checkedAt ?? this.checkedAt,
      );
  GonePage copyWithCompanion(GonePageCompanion data) {
    return GonePage(
      provider: data.provider.present ? data.provider.value : this.provider,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GonePage(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(provider, providerId, checkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GonePage &&
          other.provider == this.provider &&
          other.providerId == this.providerId &&
          other.checkedAt == this.checkedAt);
}

class GonePageCompanion extends UpdateCompanion<GonePage> {
  final Value<String> provider;
  final Value<int> providerId;
  final Value<int> checkedAt;
  final Value<int> rowid;
  const GonePageCompanion({
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GonePageCompanion.insert({
    required String provider,
    required int providerId,
    required int checkedAt,
    this.rowid = const Value.absent(),
  }) : provider = Value(provider),
       providerId = Value(providerId),
       checkedAt = Value(checkedAt);
  static Insertable<GonePage> custom({
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<int>? checkedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GonePageCompanion copyWith({
    Value<String>? provider,
    Value<int>? providerId,
    Value<int>? checkedAt,
    Value<int>? rowid,
  }) {
    return GonePageCompanion(
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      checkedAt: checkedAt ?? this.checkedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<int>(checkedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GonePageCompanion(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ScanScheduleTable extends Table
    with TableInfo<ScanScheduleTable, ScanSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ScanScheduleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  static const VerificationMeta _lastCheckAtMeta = const VerificationMeta(
    'lastCheckAt',
  );
  late final GeneratedColumn<int> lastCheckAt = GeneratedColumn<int>(
    'last_check_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nextCheckAtMeta = const VerificationMeta(
    'nextCheckAt',
  );
  late final GeneratedColumn<int> nextCheckAt = GeneratedColumn<int>(
    'next_check_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _quietStreakMeta = const VerificationMeta(
    'quietStreak',
  );
  late final GeneratedColumn<int> quietStreak = GeneratedColumn<int>(
    'quiet_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    provider,
    providerId,
    lastCheckAt,
    nextCheckAt,
    quietStreak,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_schedule';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('last_check_at')) {
      context.handle(
        _lastCheckAtMeta,
        lastCheckAt.isAcceptableOrUnknown(
          data['last_check_at']!,
          _lastCheckAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastCheckAtMeta);
    }
    if (data.containsKey('next_check_at')) {
      context.handle(
        _nextCheckAtMeta,
        nextCheckAt.isAcceptableOrUnknown(
          data['next_check_at']!,
          _nextCheckAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextCheckAtMeta);
    }
    if (data.containsKey('quiet_streak')) {
      context.handle(
        _quietStreakMeta,
        quietStreak.isAcceptableOrUnknown(
          data['quiet_streak']!,
          _quietStreakMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {provider, providerId};
  @override
  ScanSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSchedule(
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      lastCheckAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_check_at'],
      )!,
      nextCheckAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_check_at'],
      )!,
      quietStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_streak'],
      )!,
    );
  }

  @override
  ScanScheduleTable createAlias(String alias) {
    return ScanScheduleTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(provider, provider_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ScanSchedule extends DataClass implements Insertable<ScanSchedule> {
  final String provider;
  final int providerId;
  final int lastCheckAt;
  final int nextCheckAt;
  final int quietStreak;
  const ScanSchedule({
    required this.provider,
    required this.providerId,
    required this.lastCheckAt,
    required this.nextCheckAt,
    required this.quietStreak,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['last_check_at'] = Variable<int>(lastCheckAt);
    map['next_check_at'] = Variable<int>(nextCheckAt);
    map['quiet_streak'] = Variable<int>(quietStreak);
    return map;
  }

  ScanScheduleCompanion toCompanion(bool nullToAbsent) {
    return ScanScheduleCompanion(
      provider: Value(provider),
      providerId: Value(providerId),
      lastCheckAt: Value(lastCheckAt),
      nextCheckAt: Value(nextCheckAt),
      quietStreak: Value(quietStreak),
    );
  }

  factory ScanSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanSchedule(
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
      lastCheckAt: serializer.fromJson<int>(json['last_check_at']),
      nextCheckAt: serializer.fromJson<int>(json['next_check_at']),
      quietStreak: serializer.fromJson<int>(json['quiet_streak']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
      'last_check_at': serializer.toJson<int>(lastCheckAt),
      'next_check_at': serializer.toJson<int>(nextCheckAt),
      'quiet_streak': serializer.toJson<int>(quietStreak),
    };
  }

  ScanSchedule copyWith({
    String? provider,
    int? providerId,
    int? lastCheckAt,
    int? nextCheckAt,
    int? quietStreak,
  }) => ScanSchedule(
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    lastCheckAt: lastCheckAt ?? this.lastCheckAt,
    nextCheckAt: nextCheckAt ?? this.nextCheckAt,
    quietStreak: quietStreak ?? this.quietStreak,
  );
  ScanSchedule copyWithCompanion(ScanScheduleCompanion data) {
    return ScanSchedule(
      provider: data.provider.present ? data.provider.value : this.provider,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      lastCheckAt: data.lastCheckAt.present
          ? data.lastCheckAt.value
          : this.lastCheckAt,
      nextCheckAt: data.nextCheckAt.present
          ? data.nextCheckAt.value
          : this.nextCheckAt,
      quietStreak: data.quietStreak.present
          ? data.quietStreak.value
          : this.quietStreak,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanSchedule(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('lastCheckAt: $lastCheckAt, ')
          ..write('nextCheckAt: $nextCheckAt, ')
          ..write('quietStreak: $quietStreak')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(provider, providerId, lastCheckAt, nextCheckAt, quietStreak);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSchedule &&
          other.provider == this.provider &&
          other.providerId == this.providerId &&
          other.lastCheckAt == this.lastCheckAt &&
          other.nextCheckAt == this.nextCheckAt &&
          other.quietStreak == this.quietStreak);
}

class ScanScheduleCompanion extends UpdateCompanion<ScanSchedule> {
  final Value<String> provider;
  final Value<int> providerId;
  final Value<int> lastCheckAt;
  final Value<int> nextCheckAt;
  final Value<int> quietStreak;
  final Value<int> rowid;
  const ScanScheduleCompanion({
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.lastCheckAt = const Value.absent(),
    this.nextCheckAt = const Value.absent(),
    this.quietStreak = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanScheduleCompanion.insert({
    required String provider,
    required int providerId,
    required int lastCheckAt,
    required int nextCheckAt,
    this.quietStreak = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : provider = Value(provider),
       providerId = Value(providerId),
       lastCheckAt = Value(lastCheckAt),
       nextCheckAt = Value(nextCheckAt);
  static Insertable<ScanSchedule> custom({
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<int>? lastCheckAt,
    Expression<int>? nextCheckAt,
    Expression<int>? quietStreak,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (lastCheckAt != null) 'last_check_at': lastCheckAt,
      if (nextCheckAt != null) 'next_check_at': nextCheckAt,
      if (quietStreak != null) 'quiet_streak': quietStreak,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanScheduleCompanion copyWith({
    Value<String>? provider,
    Value<int>? providerId,
    Value<int>? lastCheckAt,
    Value<int>? nextCheckAt,
    Value<int>? quietStreak,
    Value<int>? rowid,
  }) {
    return ScanScheduleCompanion(
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      lastCheckAt: lastCheckAt ?? this.lastCheckAt,
      nextCheckAt: nextCheckAt ?? this.nextCheckAt,
      quietStreak: quietStreak ?? this.quietStreak,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (lastCheckAt.present) {
      map['last_check_at'] = Variable<int>(lastCheckAt.value);
    }
    if (nextCheckAt.present) {
      map['next_check_at'] = Variable<int>(nextCheckAt.value);
    }
    if (quietStreak.present) {
      map['quiet_streak'] = Variable<int>(quietStreak.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanScheduleCompanion(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('lastCheckAt: $lastCheckAt, ')
          ..write('nextCheckAt: $nextCheckAt, ')
          ..write('quietStreak: $quietStreak, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MatchSuggestionTable extends Table
    with TableInfo<MatchSuggestionTable, MatchSuggestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MatchSuggestionTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _foundAtMeta = const VerificationMeta(
    'foundAt',
  );
  late final GeneratedColumn<int> foundAt = GeneratedColumn<int>(
    'found_at',
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
    position,
    json,
    foundAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_suggestion';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchSuggestion> instance, {
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
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('found_at')) {
      context.handle(
        _foundAtMeta,
        foundAt.isAcceptableOrUnknown(data['found_at']!, _foundAtMeta),
      );
    } else if (isInserting) {
      context.missing(_foundAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, provider, providerId};
  @override
  MatchSuggestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchSuggestion(
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
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      foundAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}found_at'],
      )!,
    );
  }

  @override
  MatchSuggestionTable createAlias(String alias) {
    return MatchSuggestionTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(entry_id, provider, provider_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MatchSuggestion extends DataClass implements Insertable<MatchSuggestion> {
  final String entryId;
  final String provider;
  final int providerId;
  final int position;
  final String json;
  final int foundAt;
  const MatchSuggestion({
    required this.entryId,
    required this.provider,
    required this.providerId,
    required this.position,
    required this.json,
    required this.foundAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['position'] = Variable<int>(position);
    map['json'] = Variable<String>(json);
    map['found_at'] = Variable<int>(foundAt);
    return map;
  }

  MatchSuggestionCompanion toCompanion(bool nullToAbsent) {
    return MatchSuggestionCompanion(
      entryId: Value(entryId),
      provider: Value(provider),
      providerId: Value(providerId),
      position: Value(position),
      json: Value(json),
      foundAt: Value(foundAt),
    );
  }

  factory MatchSuggestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchSuggestion(
      entryId: serializer.fromJson<String>(json['entry_id']),
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
      position: serializer.fromJson<int>(json['position']),
      json: serializer.fromJson<String>(json['json']),
      foundAt: serializer.fromJson<int>(json['found_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
      'position': serializer.toJson<int>(position),
      'json': serializer.toJson<String>(json),
      'found_at': serializer.toJson<int>(foundAt),
    };
  }

  MatchSuggestion copyWith({
    String? entryId,
    String? provider,
    int? providerId,
    int? position,
    String? json,
    int? foundAt,
  }) => MatchSuggestion(
    entryId: entryId ?? this.entryId,
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    position: position ?? this.position,
    json: json ?? this.json,
    foundAt: foundAt ?? this.foundAt,
  );
  MatchSuggestion copyWithCompanion(MatchSuggestionCompanion data) {
    return MatchSuggestion(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      position: data.position.present ? data.position.value : this.position,
      json: data.json.present ? data.json.value : this.json,
      foundAt: data.foundAt.present ? data.foundAt.value : this.foundAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchSuggestion(')
          ..write('entryId: $entryId, ')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('position: $position, ')
          ..write('json: $json, ')
          ..write('foundAt: $foundAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entryId, provider, providerId, position, json, foundAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchSuggestion &&
          other.entryId == this.entryId &&
          other.provider == this.provider &&
          other.providerId == this.providerId &&
          other.position == this.position &&
          other.json == this.json &&
          other.foundAt == this.foundAt);
}

class MatchSuggestionCompanion extends UpdateCompanion<MatchSuggestion> {
  final Value<String> entryId;
  final Value<String> provider;
  final Value<int> providerId;
  final Value<int> position;
  final Value<String> json;
  final Value<int> foundAt;
  final Value<int> rowid;
  const MatchSuggestionCompanion({
    this.entryId = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.position = const Value.absent(),
    this.json = const Value.absent(),
    this.foundAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchSuggestionCompanion.insert({
    required String entryId,
    required String provider,
    required int providerId,
    required int position,
    required String json,
    required int foundAt,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       provider = Value(provider),
       providerId = Value(providerId),
       position = Value(position),
       json = Value(json),
       foundAt = Value(foundAt);
  static Insertable<MatchSuggestion> custom({
    Expression<String>? entryId,
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<int>? position,
    Expression<String>? json,
    Expression<int>? foundAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (position != null) 'position': position,
      if (json != null) 'json': json,
      if (foundAt != null) 'found_at': foundAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchSuggestionCompanion copyWith({
    Value<String>? entryId,
    Value<String>? provider,
    Value<int>? providerId,
    Value<int>? position,
    Value<String>? json,
    Value<int>? foundAt,
    Value<int>? rowid,
  }) {
    return MatchSuggestionCompanion(
      entryId: entryId ?? this.entryId,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      position: position ?? this.position,
      json: json ?? this.json,
      foundAt: foundAt ?? this.foundAt,
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
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (foundAt.present) {
      map['found_at'] = Variable<int>(foundAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchSuggestionCompanion(')
          ..write('entryId: $entryId, ')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('position: $position, ')
          ..write('json: $json, ')
          ..write('foundAt: $foundAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MatchAttemptTable extends Table
    with TableInfo<MatchAttemptTable, MatchAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MatchAttemptTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _searchedAtMeta = const VerificationMeta(
    'searchedAt',
  );
  late final GeneratedColumn<int> searchedAt = GeneratedColumn<int>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_attempt';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchAttempt> instance, {
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
    if (data.containsKey('searched_at')) {
      context.handle(
        _searchedAtMeta,
        searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  MatchAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchAttempt(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      searchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}searched_at'],
      )!,
    );
  }

  @override
  MatchAttemptTable createAlias(String alias) {
    return MatchAttemptTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MatchAttempt extends DataClass implements Insertable<MatchAttempt> {
  final String entryId;
  final int searchedAt;
  const MatchAttempt({required this.entryId, required this.searchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['searched_at'] = Variable<int>(searchedAt);
    return map;
  }

  MatchAttemptCompanion toCompanion(bool nullToAbsent) {
    return MatchAttemptCompanion(
      entryId: Value(entryId),
      searchedAt: Value(searchedAt),
    );
  }

  factory MatchAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchAttempt(
      entryId: serializer.fromJson<String>(json['entry_id']),
      searchedAt: serializer.fromJson<int>(json['searched_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'searched_at': serializer.toJson<int>(searchedAt),
    };
  }

  MatchAttempt copyWith({String? entryId, int? searchedAt}) => MatchAttempt(
    entryId: entryId ?? this.entryId,
    searchedAt: searchedAt ?? this.searchedAt,
  );
  MatchAttempt copyWithCompanion(MatchAttemptCompanion data) {
    return MatchAttempt(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      searchedAt: data.searchedAt.present
          ? data.searchedAt.value
          : this.searchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchAttempt(')
          ..write('entryId: $entryId, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchAttempt &&
          other.entryId == this.entryId &&
          other.searchedAt == this.searchedAt);
}

class MatchAttemptCompanion extends UpdateCompanion<MatchAttempt> {
  final Value<String> entryId;
  final Value<int> searchedAt;
  final Value<int> rowid;
  const MatchAttemptCompanion({
    this.entryId = const Value.absent(),
    this.searchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchAttemptCompanion.insert({
    required String entryId,
    required int searchedAt,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       searchedAt = Value(searchedAt);
  static Insertable<MatchAttempt> custom({
    Expression<String>? entryId,
    Expression<int>? searchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (searchedAt != null) 'searched_at': searchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchAttemptCompanion copyWith({
    Value<String>? entryId,
    Value<int>? searchedAt,
    Value<int>? rowid,
  }) {
    return MatchAttemptCompanion(
      entryId: entryId ?? this.entryId,
      searchedAt: searchedAt ?? this.searchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<int>(searchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchAttemptCompanion(')
          ..write('entryId: $entryId, ')
          ..write('searchedAt: $searchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SearchCache extends Table with TableInfo<SearchCache, SearchCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SearchCache(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryHashMeta = const VerificationMeta(
    'queryHash',
  );
  late final GeneratedColumn<String> queryHash = GeneratedColumn<String>(
    'query_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _queryTextMeta = const VerificationMeta(
    'queryText',
  );
  late final GeneratedColumn<String> queryText = GeneratedColumn<String>(
    'query_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _resultsMeta = const VerificationMeta(
    'results',
  );
  late final GeneratedColumn<String> results = GeneratedColumn<String>(
    'results',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    queryHash,
    queryText,
    results,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query_hash')) {
      context.handle(
        _queryHashMeta,
        queryHash.isAcceptableOrUnknown(data['query_hash']!, _queryHashMeta),
      );
    } else if (isInserting) {
      context.missing(_queryHashMeta);
    }
    if (data.containsKey('query_text')) {
      context.handle(
        _queryTextMeta,
        queryText.isAcceptableOrUnknown(data['query_text']!, _queryTextMeta),
      );
    } else if (isInserting) {
      context.missing(_queryTextMeta);
    }
    if (data.containsKey('results')) {
      context.handle(
        _resultsMeta,
        results.isAcceptableOrUnknown(data['results']!, _resultsMeta),
      );
    } else if (isInserting) {
      context.missing(_resultsMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {queryHash};
  @override
  SearchCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchCacheRow(
      queryHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query_hash'],
      )!,
      queryText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query_text'],
      )!,
      results: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}results'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  SearchCache createAlias(String alias) {
    return SearchCache(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SearchCacheRow extends DataClass implements Insertable<SearchCacheRow> {
  final String queryHash;
  final String queryText;
  final String results;
  final int cachedAt;
  const SearchCacheRow({
    required this.queryHash,
    required this.queryText,
    required this.results,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query_hash'] = Variable<String>(queryHash);
    map['query_text'] = Variable<String>(queryText);
    map['results'] = Variable<String>(results);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  SearchCacheCompanion toCompanion(bool nullToAbsent) {
    return SearchCacheCompanion(
      queryHash: Value(queryHash),
      queryText: Value(queryText),
      results: Value(results),
      cachedAt: Value(cachedAt),
    );
  }

  factory SearchCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchCacheRow(
      queryHash: serializer.fromJson<String>(json['query_hash']),
      queryText: serializer.fromJson<String>(json['query_text']),
      results: serializer.fromJson<String>(json['results']),
      cachedAt: serializer.fromJson<int>(json['cached_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query_hash': serializer.toJson<String>(queryHash),
      'query_text': serializer.toJson<String>(queryText),
      'results': serializer.toJson<String>(results),
      'cached_at': serializer.toJson<int>(cachedAt),
    };
  }

  SearchCacheRow copyWith({
    String? queryHash,
    String? queryText,
    String? results,
    int? cachedAt,
  }) => SearchCacheRow(
    queryHash: queryHash ?? this.queryHash,
    queryText: queryText ?? this.queryText,
    results: results ?? this.results,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  SearchCacheRow copyWithCompanion(SearchCacheCompanion data) {
    return SearchCacheRow(
      queryHash: data.queryHash.present ? data.queryHash.value : this.queryHash,
      queryText: data.queryText.present ? data.queryText.value : this.queryText,
      results: data.results.present ? data.results.value : this.results,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchCacheRow(')
          ..write('queryHash: $queryHash, ')
          ..write('queryText: $queryText, ')
          ..write('results: $results, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(queryHash, queryText, results, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchCacheRow &&
          other.queryHash == this.queryHash &&
          other.queryText == this.queryText &&
          other.results == this.results &&
          other.cachedAt == this.cachedAt);
}

class SearchCacheCompanion extends UpdateCompanion<SearchCacheRow> {
  final Value<String> queryHash;
  final Value<String> queryText;
  final Value<String> results;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const SearchCacheCompanion({
    this.queryHash = const Value.absent(),
    this.queryText = const Value.absent(),
    this.results = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchCacheCompanion.insert({
    required String queryHash,
    required String queryText,
    required String results,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : queryHash = Value(queryHash),
       queryText = Value(queryText),
       results = Value(results),
       cachedAt = Value(cachedAt);
  static Insertable<SearchCacheRow> custom({
    Expression<String>? queryHash,
    Expression<String>? queryText,
    Expression<String>? results,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (queryHash != null) 'query_hash': queryHash,
      if (queryText != null) 'query_text': queryText,
      if (results != null) 'results': results,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchCacheCompanion copyWith({
    Value<String>? queryHash,
    Value<String>? queryText,
    Value<String>? results,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return SearchCacheCompanion(
      queryHash: queryHash ?? this.queryHash,
      queryText: queryText ?? this.queryText,
      results: results ?? this.results,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (queryHash.present) {
      map['query_hash'] = Variable<String>(queryHash.value);
    }
    if (queryText.present) {
      map['query_text'] = Variable<String>(queryText.value);
    }
    if (results.present) {
      map['results'] = Variable<String>(results.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchCacheCompanion(')
          ..write('queryHash: $queryHash, ')
          ..write('queryText: $queryText, ')
          ..write('results: $results, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CoverTable extends Table with TableInfo<CoverTable, Cover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CoverTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  late final GeneratedColumn<String> size = GeneratedColumn<String>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (size IN (\'medium\', \'large\'))',
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _shownAtMeta = const VerificationMeta(
    'shownAt',
  );
  late final GeneratedColumn<int> shownAt = GeneratedColumn<int>(
    'shown_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    provider,
    providerId,
    size,
    url,
    fileName,
    bytes,
    fetchedAt,
    shownAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cover';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('shown_at')) {
      context.handle(
        _shownAtMeta,
        shownAt.isAcceptableOrUnknown(data['shown_at']!, _shownAtMeta),
      );
    } else if (isInserting) {
      context.missing(_shownAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {provider, providerId, size};
  @override
  Cover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cover(
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
      shownAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shown_at'],
      )!,
    );
  }

  @override
  CoverTable createAlias(String alias) {
    return CoverTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(provider, provider_id, size)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Cover extends DataClass implements Insertable<Cover> {
  final String provider;
  final int providerId;
  final String size;
  final String url;

  /// the picture link the file came from
  final String fileName;
  final int bytes;
  final int fetchedAt;
  final int shownAt;
  const Cover({
    required this.provider,
    required this.providerId,
    required this.size,
    required this.url,
    required this.fileName,
    required this.bytes,
    required this.fetchedAt,
    required this.shownAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['size'] = Variable<String>(size);
    map['url'] = Variable<String>(url);
    map['file_name'] = Variable<String>(fileName);
    map['bytes'] = Variable<int>(bytes);
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['shown_at'] = Variable<int>(shownAt);
    return map;
  }

  CoverCompanion toCompanion(bool nullToAbsent) {
    return CoverCompanion(
      provider: Value(provider),
      providerId: Value(providerId),
      size: Value(size),
      url: Value(url),
      fileName: Value(fileName),
      bytes: Value(bytes),
      fetchedAt: Value(fetchedAt),
      shownAt: Value(shownAt),
    );
  }

  factory Cover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cover(
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
      size: serializer.fromJson<String>(json['size']),
      url: serializer.fromJson<String>(json['url']),
      fileName: serializer.fromJson<String>(json['file_name']),
      bytes: serializer.fromJson<int>(json['bytes']),
      fetchedAt: serializer.fromJson<int>(json['fetched_at']),
      shownAt: serializer.fromJson<int>(json['shown_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
      'size': serializer.toJson<String>(size),
      'url': serializer.toJson<String>(url),
      'file_name': serializer.toJson<String>(fileName),
      'bytes': serializer.toJson<int>(bytes),
      'fetched_at': serializer.toJson<int>(fetchedAt),
      'shown_at': serializer.toJson<int>(shownAt),
    };
  }

  Cover copyWith({
    String? provider,
    int? providerId,
    String? size,
    String? url,
    String? fileName,
    int? bytes,
    int? fetchedAt,
    int? shownAt,
  }) => Cover(
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    size: size ?? this.size,
    url: url ?? this.url,
    fileName: fileName ?? this.fileName,
    bytes: bytes ?? this.bytes,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    shownAt: shownAt ?? this.shownAt,
  );
  Cover copyWithCompanion(CoverCompanion data) {
    return Cover(
      provider: data.provider.present ? data.provider.value : this.provider,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      size: data.size.present ? data.size.value : this.size,
      url: data.url.present ? data.url.value : this.url,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      shownAt: data.shownAt.present ? data.shownAt.value : this.shownAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cover(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('size: $size, ')
          ..write('url: $url, ')
          ..write('fileName: $fileName, ')
          ..write('bytes: $bytes, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('shownAt: $shownAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    provider,
    providerId,
    size,
    url,
    fileName,
    bytes,
    fetchedAt,
    shownAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cover &&
          other.provider == this.provider &&
          other.providerId == this.providerId &&
          other.size == this.size &&
          other.url == this.url &&
          other.fileName == this.fileName &&
          other.bytes == this.bytes &&
          other.fetchedAt == this.fetchedAt &&
          other.shownAt == this.shownAt);
}

class CoverCompanion extends UpdateCompanion<Cover> {
  final Value<String> provider;
  final Value<int> providerId;
  final Value<String> size;
  final Value<String> url;
  final Value<String> fileName;
  final Value<int> bytes;
  final Value<int> fetchedAt;
  final Value<int> shownAt;
  final Value<int> rowid;
  const CoverCompanion({
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.size = const Value.absent(),
    this.url = const Value.absent(),
    this.fileName = const Value.absent(),
    this.bytes = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.shownAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoverCompanion.insert({
    required String provider,
    required int providerId,
    required String size,
    required String url,
    required String fileName,
    required int bytes,
    required int fetchedAt,
    required int shownAt,
    this.rowid = const Value.absent(),
  }) : provider = Value(provider),
       providerId = Value(providerId),
       size = Value(size),
       url = Value(url),
       fileName = Value(fileName),
       bytes = Value(bytes),
       fetchedAt = Value(fetchedAt),
       shownAt = Value(shownAt);
  static Insertable<Cover> custom({
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<String>? size,
    Expression<String>? url,
    Expression<String>? fileName,
    Expression<int>? bytes,
    Expression<int>? fetchedAt,
    Expression<int>? shownAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (size != null) 'size': size,
      if (url != null) 'url': url,
      if (fileName != null) 'file_name': fileName,
      if (bytes != null) 'bytes': bytes,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (shownAt != null) 'shown_at': shownAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoverCompanion copyWith({
    Value<String>? provider,
    Value<int>? providerId,
    Value<String>? size,
    Value<String>? url,
    Value<String>? fileName,
    Value<int>? bytes,
    Value<int>? fetchedAt,
    Value<int>? shownAt,
    Value<int>? rowid,
  }) {
    return CoverCompanion(
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      size: size ?? this.size,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      bytes: bytes ?? this.bytes,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      shownAt: shownAt ?? this.shownAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (size.present) {
      map['size'] = Variable<String>(size.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (shownAt.present) {
      map['shown_at'] = Variable<int>(shownAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoverCompanion(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('size: $size, ')
          ..write('url: $url, ')
          ..write('fileName: $fileName, ')
          ..write('bytes: $bytes, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('shownAt: $shownAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DetailsDatabase extends GeneratedDatabase {
  _$DetailsDatabase(QueryExecutor e) : super(e);
  $DetailsDatabaseManager get managers => $DetailsDatabaseManager(this);
  late final DetailTable detail = DetailTable(this);
  late final FranchiseLinkTable franchiseLink = FranchiseLinkTable(this);
  late final Index idxFranchise = Index(
    'idx_franchise',
    'CREATE INDEX idx_franchise ON franchise_link (franchise_provider, franchise_provider_id)',
  );
  late final GonePageTable gonePage = GonePageTable(this);
  late final ScanScheduleTable scanSchedule = ScanScheduleTable(this);
  late final Index idxScanDue = Index(
    'idx_scan_due',
    'CREATE INDEX idx_scan_due ON scan_schedule (next_check_at)',
  );
  late final MatchSuggestionTable matchSuggestion = MatchSuggestionTable(this);
  late final MatchAttemptTable matchAttempt = MatchAttemptTable(this);
  late final SearchCache searchCache = SearchCache(this);
  late final CoverTable cover = CoverTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    detail,
    franchiseLink,
    idxFranchise,
    gonePage,
    scanSchedule,
    idxScanDue,
    matchSuggestion,
    matchAttempt,
    searchCache,
    cover,
  ];
}

typedef $DetailTableCreateCompanionBuilder = DetailCompanion Function({
  required String provider,
  required int providerId,
  required int fetchedAt,
  required String json,
  Value<bool> isFull,
  Value<int> rowid,
});
typedef $DetailTableUpdateCompanionBuilder = DetailCompanion Function({
  Value<String> provider,
  Value<int> providerId,
  Value<int> fetchedAt,
  Value<String> json,
  Value<bool> isFull,
  Value<int> rowid,
});

class $DetailTableFilterComposer
    extends Composer<_$DetailsDatabase, DetailTable> {
  $DetailTableFilterComposer({
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

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFull => $composableBuilder(
    column: $table.isFull,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleEnglish => $composableBuilder(
    column: $table.titleEnglish,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleJapanese => $composableBuilder(
    column: $table.titleJapanese,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get airingStatus => $composableBuilder(
    column: $table.airingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodes => $composableBuilder(
    column: $table.episodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverMediumUrl => $composableBuilder(
    column: $table.coverMediumUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverLargeUrl => $composableBuilder(
    column: $table.coverLargeUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nsfw => $composableBuilder(
    column: $table.nsfw,
    builder: (column) => ColumnFilters(column),
  );
}

class $DetailTableOrderingComposer
    extends Composer<_$DetailsDatabase, DetailTable> {
  $DetailTableOrderingComposer({
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

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFull => $composableBuilder(
    column: $table.isFull,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleEnglish => $composableBuilder(
    column: $table.titleEnglish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleJapanese => $composableBuilder(
    column: $table.titleJapanese,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get airingStatus => $composableBuilder(
    column: $table.airingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodes => $composableBuilder(
    column: $table.episodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverMediumUrl => $composableBuilder(
    column: $table.coverMediumUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverLargeUrl => $composableBuilder(
    column: $table.coverLargeUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nsfw => $composableBuilder(
    column: $table.nsfw,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DetailTableAnnotationComposer
    extends Composer<_$DetailsDatabase, DetailTable> {
  $DetailTableAnnotationComposer({
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

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<bool> get isFull =>
      $composableBuilder(column: $table.isFull, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleEnglish => $composableBuilder(
    column: $table.titleEnglish,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleJapanese => $composableBuilder(
    column: $table.titleJapanese,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get airingStatus => $composableBuilder(
    column: $table.airingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodes =>
      $composableBuilder(column: $table.episodes, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get coverMediumUrl => $composableBuilder(
    column: $table.coverMediumUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverLargeUrl => $composableBuilder(
    column: $table.coverLargeUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nsfw =>
      $composableBuilder(column: $table.nsfw, builder: (column) => column);
}

class $DetailTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          DetailTable,
          Detail,
          $DetailTableFilterComposer,
          $DetailTableOrderingComposer,
          $DetailTableAnnotationComposer,
          $DetailTableCreateCompanionBuilder,
          $DetailTableUpdateCompanionBuilder,
          (Detail, BaseReferences<_$DetailsDatabase, DetailTable, Detail>),
          Detail,
          PrefetchHooks Function()
        > {
  $DetailTableTableManager(_$DetailsDatabase db, DetailTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DetailTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DetailTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DetailTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<bool> isFull = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetailCompanion(
                provider: provider,
                providerId: providerId,
                fetchedAt: fetchedAt,
                json: json,
                isFull: isFull,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required int providerId,
                required int fetchedAt,
                required String json,
                Value<bool> isFull = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetailCompanion.insert(
                provider: provider,
                providerId: providerId,
                fetchedAt: fetchedAt,
                json: json,
                isFull: isFull,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DetailTable, Detail>(table),
                  BaseReferences<_$DetailsDatabase, DetailTable, Detail>(
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

typedef $DetailTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      DetailTable,
      Detail,
      $DetailTableFilterComposer,
      $DetailTableOrderingComposer,
      $DetailTableAnnotationComposer,
      $DetailTableCreateCompanionBuilder,
      $DetailTableUpdateCompanionBuilder,
      (Detail, BaseReferences<_$DetailsDatabase, DetailTable, Detail>),
      Detail,
      PrefetchHooks Function()
    >;
typedef $FranchiseLinkTableCreateCompanionBuilder =
    FranchiseLinkCompanion Function({
      required String entryId,
      required String franchiseProvider,
      required int franchiseProviderId,
      Value<bool> isExtra,
      Value<bool> isPlaceholder,
      Value<int> rowid,
    });
typedef $FranchiseLinkTableUpdateCompanionBuilder =
    FranchiseLinkCompanion Function({
      Value<String> entryId,
      Value<String> franchiseProvider,
      Value<int> franchiseProviderId,
      Value<bool> isExtra,
      Value<bool> isPlaceholder,
      Value<int> rowid,
    });

class $FranchiseLinkTableFilterComposer
    extends Composer<_$DetailsDatabase, FranchiseLinkTable> {
  $FranchiseLinkTableFilterComposer({
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

  ColumnFilters<String> get franchiseProvider => $composableBuilder(
    column: $table.franchiseProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get franchiseProviderId => $composableBuilder(
    column: $table.franchiseProviderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExtra => $composableBuilder(
    column: $table.isExtra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlaceholder => $composableBuilder(
    column: $table.isPlaceholder,
    builder: (column) => ColumnFilters(column),
  );
}

class $FranchiseLinkTableOrderingComposer
    extends Composer<_$DetailsDatabase, FranchiseLinkTable> {
  $FranchiseLinkTableOrderingComposer({
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

  ColumnOrderings<String> get franchiseProvider => $composableBuilder(
    column: $table.franchiseProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get franchiseProviderId => $composableBuilder(
    column: $table.franchiseProviderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExtra => $composableBuilder(
    column: $table.isExtra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlaceholder => $composableBuilder(
    column: $table.isPlaceholder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FranchiseLinkTableAnnotationComposer
    extends Composer<_$DetailsDatabase, FranchiseLinkTable> {
  $FranchiseLinkTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get franchiseProvider => $composableBuilder(
    column: $table.franchiseProvider,
    builder: (column) => column,
  );

  GeneratedColumn<int> get franchiseProviderId => $composableBuilder(
    column: $table.franchiseProviderId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isExtra =>
      $composableBuilder(column: $table.isExtra, builder: (column) => column);

  GeneratedColumn<bool> get isPlaceholder => $composableBuilder(
    column: $table.isPlaceholder,
    builder: (column) => column,
  );
}

class $FranchiseLinkTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          FranchiseLinkTable,
          FranchiseLink,
          $FranchiseLinkTableFilterComposer,
          $FranchiseLinkTableOrderingComposer,
          $FranchiseLinkTableAnnotationComposer,
          $FranchiseLinkTableCreateCompanionBuilder,
          $FranchiseLinkTableUpdateCompanionBuilder,
          (
            FranchiseLink,
            BaseReferences<
              _$DetailsDatabase,
              FranchiseLinkTable,
              FranchiseLink
            >,
          ),
          FranchiseLink,
          PrefetchHooks Function()
        > {
  $FranchiseLinkTableTableManager(
    _$DetailsDatabase db,
    FranchiseLinkTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FranchiseLinkTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FranchiseLinkTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FranchiseLinkTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> franchiseProvider = const Value.absent(),
                Value<int> franchiseProviderId = const Value.absent(),
                Value<bool> isExtra = const Value.absent(),
                Value<bool> isPlaceholder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FranchiseLinkCompanion(
                entryId: entryId,
                franchiseProvider: franchiseProvider,
                franchiseProviderId: franchiseProviderId,
                isExtra: isExtra,
                isPlaceholder: isPlaceholder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String franchiseProvider,
                required int franchiseProviderId,
                Value<bool> isExtra = const Value.absent(),
                Value<bool> isPlaceholder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FranchiseLinkCompanion.insert(
                entryId: entryId,
                franchiseProvider: franchiseProvider,
                franchiseProviderId: franchiseProviderId,
                isExtra: isExtra,
                isPlaceholder: isPlaceholder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<FranchiseLinkTable, FranchiseLink>(table),
                  BaseReferences<
                    _$DetailsDatabase,
                    FranchiseLinkTable,
                    FranchiseLink
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $FranchiseLinkTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      FranchiseLinkTable,
      FranchiseLink,
      $FranchiseLinkTableFilterComposer,
      $FranchiseLinkTableOrderingComposer,
      $FranchiseLinkTableAnnotationComposer,
      $FranchiseLinkTableCreateCompanionBuilder,
      $FranchiseLinkTableUpdateCompanionBuilder,
      (
        FranchiseLink,
        BaseReferences<_$DetailsDatabase, FranchiseLinkTable, FranchiseLink>,
      ),
      FranchiseLink,
      PrefetchHooks Function()
    >;
typedef $GonePageTableCreateCompanionBuilder = GonePageCompanion Function({
  required String provider,
  required int providerId,
  required int checkedAt,
  Value<int> rowid,
});
typedef $GonePageTableUpdateCompanionBuilder = GonePageCompanion Function({
  Value<String> provider,
  Value<int> providerId,
  Value<int> checkedAt,
  Value<int> rowid,
});

class $GonePageTableFilterComposer
    extends Composer<_$DetailsDatabase, GonePageTable> {
  $GonePageTableFilterComposer({
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

  ColumnFilters<int> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $GonePageTableOrderingComposer
    extends Composer<_$DetailsDatabase, GonePageTable> {
  $GonePageTableOrderingComposer({
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

  ColumnOrderings<int> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $GonePageTableAnnotationComposer
    extends Composer<_$DetailsDatabase, GonePageTable> {
  $GonePageTableAnnotationComposer({
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

  GeneratedColumn<int> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);
}

class $GonePageTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          GonePageTable,
          GonePage,
          $GonePageTableFilterComposer,
          $GonePageTableOrderingComposer,
          $GonePageTableAnnotationComposer,
          $GonePageTableCreateCompanionBuilder,
          $GonePageTableUpdateCompanionBuilder,
          (
            GonePage,
            BaseReferences<_$DetailsDatabase, GonePageTable, GonePage>,
          ),
          GonePage,
          PrefetchHooks Function()
        > {
  $GonePageTableTableManager(_$DetailsDatabase db, GonePageTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $GonePageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $GonePageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $GonePageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> checkedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GonePageCompanion(
                provider: provider,
                providerId: providerId,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required int providerId,
                required int checkedAt,
                Value<int> rowid = const Value.absent(),
              }) => GonePageCompanion.insert(
                provider: provider,
                providerId: providerId,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<GonePageTable, GonePage>(table),
                  BaseReferences<_$DetailsDatabase, GonePageTable, GonePage>(
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

typedef $GonePageTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      GonePageTable,
      GonePage,
      $GonePageTableFilterComposer,
      $GonePageTableOrderingComposer,
      $GonePageTableAnnotationComposer,
      $GonePageTableCreateCompanionBuilder,
      $GonePageTableUpdateCompanionBuilder,
      (GonePage, BaseReferences<_$DetailsDatabase, GonePageTable, GonePage>),
      GonePage,
      PrefetchHooks Function()
    >;
typedef $ScanScheduleTableCreateCompanionBuilder =
    ScanScheduleCompanion Function({
      required String provider,
      required int providerId,
      required int lastCheckAt,
      required int nextCheckAt,
      Value<int> quietStreak,
      Value<int> rowid,
    });
typedef $ScanScheduleTableUpdateCompanionBuilder =
    ScanScheduleCompanion Function({
      Value<String> provider,
      Value<int> providerId,
      Value<int> lastCheckAt,
      Value<int> nextCheckAt,
      Value<int> quietStreak,
      Value<int> rowid,
    });

class $ScanScheduleTableFilterComposer
    extends Composer<_$DetailsDatabase, ScanScheduleTable> {
  $ScanScheduleTableFilterComposer({
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

  ColumnFilters<int> get lastCheckAt => $composableBuilder(
    column: $table.lastCheckAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextCheckAt => $composableBuilder(
    column: $table.nextCheckAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietStreak => $composableBuilder(
    column: $table.quietStreak,
    builder: (column) => ColumnFilters(column),
  );
}

class $ScanScheduleTableOrderingComposer
    extends Composer<_$DetailsDatabase, ScanScheduleTable> {
  $ScanScheduleTableOrderingComposer({
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

  ColumnOrderings<int> get lastCheckAt => $composableBuilder(
    column: $table.lastCheckAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextCheckAt => $composableBuilder(
    column: $table.nextCheckAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietStreak => $composableBuilder(
    column: $table.quietStreak,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ScanScheduleTableAnnotationComposer
    extends Composer<_$DetailsDatabase, ScanScheduleTable> {
  $ScanScheduleTableAnnotationComposer({
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

  GeneratedColumn<int> get lastCheckAt => $composableBuilder(
    column: $table.lastCheckAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextCheckAt => $composableBuilder(
    column: $table.nextCheckAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietStreak => $composableBuilder(
    column: $table.quietStreak,
    builder: (column) => column,
  );
}

class $ScanScheduleTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          ScanScheduleTable,
          ScanSchedule,
          $ScanScheduleTableFilterComposer,
          $ScanScheduleTableOrderingComposer,
          $ScanScheduleTableAnnotationComposer,
          $ScanScheduleTableCreateCompanionBuilder,
          $ScanScheduleTableUpdateCompanionBuilder,
          (
            ScanSchedule,
            BaseReferences<_$DetailsDatabase, ScanScheduleTable, ScanSchedule>,
          ),
          ScanSchedule,
          PrefetchHooks Function()
        > {
  $ScanScheduleTableTableManager(_$DetailsDatabase db, ScanScheduleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ScanScheduleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ScanScheduleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ScanScheduleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> lastCheckAt = const Value.absent(),
                Value<int> nextCheckAt = const Value.absent(),
                Value<int> quietStreak = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanScheduleCompanion(
                provider: provider,
                providerId: providerId,
                lastCheckAt: lastCheckAt,
                nextCheckAt: nextCheckAt,
                quietStreak: quietStreak,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required int providerId,
                required int lastCheckAt,
                required int nextCheckAt,
                Value<int> quietStreak = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanScheduleCompanion.insert(
                provider: provider,
                providerId: providerId,
                lastCheckAt: lastCheckAt,
                nextCheckAt: nextCheckAt,
                quietStreak: quietStreak,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ScanScheduleTable, ScanSchedule>(table),
                  BaseReferences<
                    _$DetailsDatabase,
                    ScanScheduleTable,
                    ScanSchedule
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ScanScheduleTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      ScanScheduleTable,
      ScanSchedule,
      $ScanScheduleTableFilterComposer,
      $ScanScheduleTableOrderingComposer,
      $ScanScheduleTableAnnotationComposer,
      $ScanScheduleTableCreateCompanionBuilder,
      $ScanScheduleTableUpdateCompanionBuilder,
      (
        ScanSchedule,
        BaseReferences<_$DetailsDatabase, ScanScheduleTable, ScanSchedule>,
      ),
      ScanSchedule,
      PrefetchHooks Function()
    >;
typedef $MatchSuggestionTableCreateCompanionBuilder =
    MatchSuggestionCompanion Function({
      required String entryId,
      required String provider,
      required int providerId,
      required int position,
      required String json,
      required int foundAt,
      Value<int> rowid,
    });
typedef $MatchSuggestionTableUpdateCompanionBuilder =
    MatchSuggestionCompanion Function({
      Value<String> entryId,
      Value<String> provider,
      Value<int> providerId,
      Value<int> position,
      Value<String> json,
      Value<int> foundAt,
      Value<int> rowid,
    });

class $MatchSuggestionTableFilterComposer
    extends Composer<_$DetailsDatabase, MatchSuggestionTable> {
  $MatchSuggestionTableFilterComposer({
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

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foundAt => $composableBuilder(
    column: $table.foundAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $MatchSuggestionTableOrderingComposer
    extends Composer<_$DetailsDatabase, MatchSuggestionTable> {
  $MatchSuggestionTableOrderingComposer({
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foundAt => $composableBuilder(
    column: $table.foundAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MatchSuggestionTableAnnotationComposer
    extends Composer<_$DetailsDatabase, MatchSuggestionTable> {
  $MatchSuggestionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get foundAt =>
      $composableBuilder(column: $table.foundAt, builder: (column) => column);
}

class $MatchSuggestionTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          MatchSuggestionTable,
          MatchSuggestion,
          $MatchSuggestionTableFilterComposer,
          $MatchSuggestionTableOrderingComposer,
          $MatchSuggestionTableAnnotationComposer,
          $MatchSuggestionTableCreateCompanionBuilder,
          $MatchSuggestionTableUpdateCompanionBuilder,
          (
            MatchSuggestion,
            BaseReferences<
              _$DetailsDatabase,
              MatchSuggestionTable,
              MatchSuggestion
            >,
          ),
          MatchSuggestion,
          PrefetchHooks Function()
        > {
  $MatchSuggestionTableTableManager(
    _$DetailsDatabase db,
    MatchSuggestionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MatchSuggestionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MatchSuggestionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MatchSuggestionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> foundAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchSuggestionCompanion(
                entryId: entryId,
                provider: provider,
                providerId: providerId,
                position: position,
                json: json,
                foundAt: foundAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String provider,
                required int providerId,
                required int position,
                required String json,
                required int foundAt,
                Value<int> rowid = const Value.absent(),
              }) => MatchSuggestionCompanion.insert(
                entryId: entryId,
                provider: provider,
                providerId: providerId,
                position: position,
                json: json,
                foundAt: foundAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MatchSuggestionTable, MatchSuggestion>(table),
                  BaseReferences<
                    _$DetailsDatabase,
                    MatchSuggestionTable,
                    MatchSuggestion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MatchSuggestionTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      MatchSuggestionTable,
      MatchSuggestion,
      $MatchSuggestionTableFilterComposer,
      $MatchSuggestionTableOrderingComposer,
      $MatchSuggestionTableAnnotationComposer,
      $MatchSuggestionTableCreateCompanionBuilder,
      $MatchSuggestionTableUpdateCompanionBuilder,
      (
        MatchSuggestion,
        BaseReferences<
          _$DetailsDatabase,
          MatchSuggestionTable,
          MatchSuggestion
        >,
      ),
      MatchSuggestion,
      PrefetchHooks Function()
    >;
typedef $MatchAttemptTableCreateCompanionBuilder =
    MatchAttemptCompanion Function({
      required String entryId,
      required int searchedAt,
      Value<int> rowid,
    });
typedef $MatchAttemptTableUpdateCompanionBuilder =
    MatchAttemptCompanion Function({
      Value<String> entryId,
      Value<int> searchedAt,
      Value<int> rowid,
    });

class $MatchAttemptTableFilterComposer
    extends Composer<_$DetailsDatabase, MatchAttemptTable> {
  $MatchAttemptTableFilterComposer({
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

  ColumnFilters<int> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $MatchAttemptTableOrderingComposer
    extends Composer<_$DetailsDatabase, MatchAttemptTable> {
  $MatchAttemptTableOrderingComposer({
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

  ColumnOrderings<int> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MatchAttemptTableAnnotationComposer
    extends Composer<_$DetailsDatabase, MatchAttemptTable> {
  $MatchAttemptTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => column,
  );
}

class $MatchAttemptTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          MatchAttemptTable,
          MatchAttempt,
          $MatchAttemptTableFilterComposer,
          $MatchAttemptTableOrderingComposer,
          $MatchAttemptTableAnnotationComposer,
          $MatchAttemptTableCreateCompanionBuilder,
          $MatchAttemptTableUpdateCompanionBuilder,
          (
            MatchAttempt,
            BaseReferences<_$DetailsDatabase, MatchAttemptTable, MatchAttempt>,
          ),
          MatchAttempt,
          PrefetchHooks Function()
        > {
  $MatchAttemptTableTableManager(_$DetailsDatabase db, MatchAttemptTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MatchAttemptTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MatchAttemptTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MatchAttemptTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<int> searchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchAttemptCompanion(
                entryId: entryId,
                searchedAt: searchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required int searchedAt,
                Value<int> rowid = const Value.absent(),
              }) => MatchAttemptCompanion.insert(
                entryId: entryId,
                searchedAt: searchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MatchAttemptTable, MatchAttempt>(table),
                  BaseReferences<
                    _$DetailsDatabase,
                    MatchAttemptTable,
                    MatchAttempt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MatchAttemptTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      MatchAttemptTable,
      MatchAttempt,
      $MatchAttemptTableFilterComposer,
      $MatchAttemptTableOrderingComposer,
      $MatchAttemptTableAnnotationComposer,
      $MatchAttemptTableCreateCompanionBuilder,
      $MatchAttemptTableUpdateCompanionBuilder,
      (
        MatchAttempt,
        BaseReferences<_$DetailsDatabase, MatchAttemptTable, MatchAttempt>,
      ),
      MatchAttempt,
      PrefetchHooks Function()
    >;
typedef $SearchCacheCreateCompanionBuilder = SearchCacheCompanion Function({
  required String queryHash,
  required String queryText,
  required String results,
  required int cachedAt,
  Value<int> rowid,
});
typedef $SearchCacheUpdateCompanionBuilder = SearchCacheCompanion Function({
  Value<String> queryHash,
  Value<String> queryText,
  Value<String> results,
  Value<int> cachedAt,
  Value<int> rowid,
});

class $SearchCacheFilterComposer
    extends Composer<_$DetailsDatabase, SearchCache> {
  $SearchCacheFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get queryHash => $composableBuilder(
    column: $table.queryHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get queryText => $composableBuilder(
    column: $table.queryText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get results => $composableBuilder(
    column: $table.results,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SearchCacheOrderingComposer
    extends Composer<_$DetailsDatabase, SearchCache> {
  $SearchCacheOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get queryHash => $composableBuilder(
    column: $table.queryHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queryText => $composableBuilder(
    column: $table.queryText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get results => $composableBuilder(
    column: $table.results,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SearchCacheAnnotationComposer
    extends Composer<_$DetailsDatabase, SearchCache> {
  $SearchCacheAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get queryHash =>
      $composableBuilder(column: $table.queryHash, builder: (column) => column);

  GeneratedColumn<String> get queryText =>
      $composableBuilder(column: $table.queryText, builder: (column) => column);

  GeneratedColumn<String> get results =>
      $composableBuilder(column: $table.results, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $SearchCacheTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          SearchCache,
          SearchCacheRow,
          $SearchCacheFilterComposer,
          $SearchCacheOrderingComposer,
          $SearchCacheAnnotationComposer,
          $SearchCacheCreateCompanionBuilder,
          $SearchCacheUpdateCompanionBuilder,
          (
            SearchCacheRow,
            BaseReferences<_$DetailsDatabase, SearchCache, SearchCacheRow>,
          ),
          SearchCacheRow,
          PrefetchHooks Function()
        > {
  $SearchCacheTableManager(_$DetailsDatabase db, SearchCache table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SearchCacheFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SearchCacheOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SearchCacheAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> queryHash = const Value.absent(),
                Value<String> queryText = const Value.absent(),
                Value<String> results = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchCacheCompanion(
                queryHash: queryHash,
                queryText: queryText,
                results: results,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String queryHash,
                required String queryText,
                required String results,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchCacheCompanion.insert(
                queryHash: queryHash,
                queryText: queryText,
                results: results,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SearchCache, SearchCacheRow>(table),
                  BaseReferences<
                    _$DetailsDatabase,
                    SearchCache,
                    SearchCacheRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SearchCacheProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      SearchCache,
      SearchCacheRow,
      $SearchCacheFilterComposer,
      $SearchCacheOrderingComposer,
      $SearchCacheAnnotationComposer,
      $SearchCacheCreateCompanionBuilder,
      $SearchCacheUpdateCompanionBuilder,
      (
        SearchCacheRow,
        BaseReferences<_$DetailsDatabase, SearchCache, SearchCacheRow>,
      ),
      SearchCacheRow,
      PrefetchHooks Function()
    >;
typedef $CoverTableCreateCompanionBuilder = CoverCompanion Function({
  required String provider,
  required int providerId,
  required String size,
  required String url,
  required String fileName,
  required int bytes,
  required int fetchedAt,
  required int shownAt,
  Value<int> rowid,
});
typedef $CoverTableUpdateCompanionBuilder = CoverCompanion Function({
  Value<String> provider,
  Value<int> providerId,
  Value<String> size,
  Value<String> url,
  Value<String> fileName,
  Value<int> bytes,
  Value<int> fetchedAt,
  Value<int> shownAt,
  Value<int> rowid,
});

class $CoverTableFilterComposer
    extends Composer<_$DetailsDatabase, CoverTable> {
  $CoverTableFilterComposer({
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

  ColumnFilters<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shownAt => $composableBuilder(
    column: $table.shownAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $CoverTableOrderingComposer
    extends Composer<_$DetailsDatabase, CoverTable> {
  $CoverTableOrderingComposer({
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

  ColumnOrderings<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shownAt => $composableBuilder(
    column: $table.shownAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CoverTableAnnotationComposer
    extends Composer<_$DetailsDatabase, CoverTable> {
  $CoverTableAnnotationComposer({
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

  GeneratedColumn<String> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get shownAt =>
      $composableBuilder(column: $table.shownAt, builder: (column) => column);
}

class $CoverTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          CoverTable,
          Cover,
          $CoverTableFilterComposer,
          $CoverTableOrderingComposer,
          $CoverTableAnnotationComposer,
          $CoverTableCreateCompanionBuilder,
          $CoverTableUpdateCompanionBuilder,
          (Cover, BaseReferences<_$DetailsDatabase, CoverTable, Cover>),
          Cover,
          PrefetchHooks Function()
        > {
  $CoverTableTableManager(_$DetailsDatabase db, CoverTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CoverTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CoverTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CoverTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<String> size = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> shownAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoverCompanion(
                provider: provider,
                providerId: providerId,
                size: size,
                url: url,
                fileName: fileName,
                bytes: bytes,
                fetchedAt: fetchedAt,
                shownAt: shownAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required int providerId,
                required String size,
                required String url,
                required String fileName,
                required int bytes,
                required int fetchedAt,
                required int shownAt,
                Value<int> rowid = const Value.absent(),
              }) => CoverCompanion.insert(
                provider: provider,
                providerId: providerId,
                size: size,
                url: url,
                fileName: fileName,
                bytes: bytes,
                fetchedAt: fetchedAt,
                shownAt: shownAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<CoverTable, Cover>(table),
                  BaseReferences<_$DetailsDatabase, CoverTable, Cover>(
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

typedef $CoverTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      CoverTable,
      Cover,
      $CoverTableFilterComposer,
      $CoverTableOrderingComposer,
      $CoverTableAnnotationComposer,
      $CoverTableCreateCompanionBuilder,
      $CoverTableUpdateCompanionBuilder,
      (Cover, BaseReferences<_$DetailsDatabase, CoverTable, Cover>),
      Cover,
      PrefetchHooks Function()
    >;

class $DetailsDatabaseManager {
  final _$DetailsDatabase _db;
  $DetailsDatabaseManager(this._db);
  $DetailTableTableManager get detail =>
      $DetailTableTableManager(_db, _db.detail);
  $FranchiseLinkTableTableManager get franchiseLink =>
      $FranchiseLinkTableTableManager(_db, _db.franchiseLink);
  $GonePageTableTableManager get gonePage =>
      $GonePageTableTableManager(_db, _db.gonePage);
  $ScanScheduleTableTableManager get scanSchedule =>
      $ScanScheduleTableTableManager(_db, _db.scanSchedule);
  $MatchSuggestionTableTableManager get matchSuggestion =>
      $MatchSuggestionTableTableManager(_db, _db.matchSuggestion);
  $MatchAttemptTableTableManager get matchAttempt =>
      $MatchAttemptTableTableManager(_db, _db.matchAttempt);
  $SearchCacheTableManager get searchCache =>
      $SearchCacheTableManager(_db, _db.searchCache);
  $CoverTableTableManager get cover => $CoverTableTableManager(_db, _db.cover);
}
