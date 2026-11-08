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
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression(
        'COALESCE(json_extract(json, \'\$.main_picture.large\'), json_extract(json, \'\$.main_picture.medium\'))',
      ),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (COALESCE(json_extract(json, \'\$.main_picture.large\'), json_extract(json, \'\$.main_picture.medium\'))) VIRTUAL',
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
    title,
    titleEnglish,
    titleJapanese,
    mediaType,
    airingStatus,
    episodes,
    startDate,
    coverUrl,
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
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
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
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
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
  final String? title;
  final String? titleEnglish;
  final String? titleJapanese;
  final String? mediaType;
  final String? airingStatus;

  /// mal sends 0 when the count is not known yet
  final int? episodes;
  final String? startDate;
  final String? coverUrl;
  final String? nsfw;
  const Detail({
    required this.provider,
    required this.providerId,
    required this.fetchedAt,
    required this.json,
    this.title,
    this.titleEnglish,
    this.titleJapanese,
    this.mediaType,
    this.airingStatus,
    this.episodes,
    this.startDate,
    this.coverUrl,
    this.nsfw,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['json'] = Variable<String>(json);
    return map;
  }

  DetailCompanion toCompanion(bool nullToAbsent) {
    return DetailCompanion(
      provider: Value(provider),
      providerId: Value(providerId),
      fetchedAt: Value(fetchedAt),
      json: Value(json),
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
      title: serializer.fromJson<String?>(json['title']),
      titleEnglish: serializer.fromJson<String?>(json['title_english']),
      titleJapanese: serializer.fromJson<String?>(json['title_japanese']),
      mediaType: serializer.fromJson<String?>(json['media_type']),
      airingStatus: serializer.fromJson<String?>(json['airing_status']),
      episodes: serializer.fromJson<int?>(json['episodes']),
      startDate: serializer.fromJson<String?>(json['start_date']),
      coverUrl: serializer.fromJson<String?>(json['cover_url']),
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
      'title': serializer.toJson<String?>(title),
      'title_english': serializer.toJson<String?>(titleEnglish),
      'title_japanese': serializer.toJson<String?>(titleJapanese),
      'media_type': serializer.toJson<String?>(mediaType),
      'airing_status': serializer.toJson<String?>(airingStatus),
      'episodes': serializer.toJson<int?>(episodes),
      'start_date': serializer.toJson<String?>(startDate),
      'cover_url': serializer.toJson<String?>(coverUrl),
      'nsfw': serializer.toJson<String?>(nsfw),
    };
  }

  Detail copyWith({
    String? provider,
    int? providerId,
    int? fetchedAt,
    String? json,
    Value<String?> title = const Value.absent(),
    Value<String?> titleEnglish = const Value.absent(),
    Value<String?> titleJapanese = const Value.absent(),
    Value<String?> mediaType = const Value.absent(),
    Value<String?> airingStatus = const Value.absent(),
    Value<int?> episodes = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> nsfw = const Value.absent(),
  }) => Detail(
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    json: json ?? this.json,
    title: title.present ? title.value : this.title,
    titleEnglish: titleEnglish.present ? titleEnglish.value : this.titleEnglish,
    titleJapanese: titleJapanese.present
        ? titleJapanese.value
        : this.titleJapanese,
    mediaType: mediaType.present ? mediaType.value : this.mediaType,
    airingStatus: airingStatus.present ? airingStatus.value : this.airingStatus,
    episodes: episodes.present ? episodes.value : this.episodes,
    startDate: startDate.present ? startDate.value : this.startDate,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    nsfw: nsfw.present ? nsfw.value : this.nsfw,
  );
  @override
  String toString() {
    return (StringBuffer('Detail(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('json: $json, ')
          ..write('title: $title, ')
          ..write('titleEnglish: $titleEnglish, ')
          ..write('titleJapanese: $titleJapanese, ')
          ..write('mediaType: $mediaType, ')
          ..write('airingStatus: $airingStatus, ')
          ..write('episodes: $episodes, ')
          ..write('startDate: $startDate, ')
          ..write('coverUrl: $coverUrl, ')
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
    title,
    titleEnglish,
    titleJapanese,
    mediaType,
    airingStatus,
    episodes,
    startDate,
    coverUrl,
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
          other.title == this.title &&
          other.titleEnglish == this.titleEnglish &&
          other.titleJapanese == this.titleJapanese &&
          other.mediaType == this.mediaType &&
          other.airingStatus == this.airingStatus &&
          other.episodes == this.episodes &&
          other.startDate == this.startDate &&
          other.coverUrl == this.coverUrl &&
          other.nsfw == this.nsfw);
}

class DetailCompanion extends UpdateCompanion<Detail> {
  final Value<String> provider;
  final Value<int> providerId;
  final Value<int> fetchedAt;
  final Value<String> json;
  final Value<int> rowid;
  const DetailCompanion({
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DetailCompanion.insert({
    required String provider,
    required int providerId,
    required int fetchedAt,
    required String json,
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DetailCompanion copyWith({
    Value<String>? provider,
    Value<int>? providerId,
    Value<int>? fetchedAt,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return DetailCompanion(
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      json: json ?? this.json,
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
  static const VerificationMeta _rootProviderMeta = const VerificationMeta(
    'rootProvider',
  );
  late final GeneratedColumn<String> rootProvider = GeneratedColumn<String>(
    'root_provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rootProviderIdMeta = const VerificationMeta(
    'rootProviderId',
  );
  late final GeneratedColumn<int> rootProviderId = GeneratedColumn<int>(
    'root_provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
    rootProvider,
    rootProviderId,
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
    if (data.containsKey('root_provider')) {
      context.handle(
        _rootProviderMeta,
        rootProvider.isAcceptableOrUnknown(
          data['root_provider']!,
          _rootProviderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rootProviderMeta);
    }
    if (data.containsKey('root_provider_id')) {
      context.handle(
        _rootProviderIdMeta,
        rootProviderId.isAcceptableOrUnknown(
          data['root_provider_id']!,
          _rootProviderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rootProviderIdMeta);
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
      rootProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_provider'],
      )!,
      rootProviderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}root_provider_id'],
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
  final String rootProvider;
  final int rootProviderId;
  final bool isPlaceholder;
  const FranchiseLink({
    required this.entryId,
    required this.rootProvider,
    required this.rootProviderId,
    required this.isPlaceholder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['root_provider'] = Variable<String>(rootProvider);
    map['root_provider_id'] = Variable<int>(rootProviderId);
    map['is_placeholder'] = Variable<bool>(isPlaceholder);
    return map;
  }

  FranchiseLinkCompanion toCompanion(bool nullToAbsent) {
    return FranchiseLinkCompanion(
      entryId: Value(entryId),
      rootProvider: Value(rootProvider),
      rootProviderId: Value(rootProviderId),
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
      rootProvider: serializer.fromJson<String>(json['root_provider']),
      rootProviderId: serializer.fromJson<int>(json['root_provider_id']),
      isPlaceholder: serializer.fromJson<bool>(json['is_placeholder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'root_provider': serializer.toJson<String>(rootProvider),
      'root_provider_id': serializer.toJson<int>(rootProviderId),
      'is_placeholder': serializer.toJson<bool>(isPlaceholder),
    };
  }

  FranchiseLink copyWith({
    String? entryId,
    String? rootProvider,
    int? rootProviderId,
    bool? isPlaceholder,
  }) => FranchiseLink(
    entryId: entryId ?? this.entryId,
    rootProvider: rootProvider ?? this.rootProvider,
    rootProviderId: rootProviderId ?? this.rootProviderId,
    isPlaceholder: isPlaceholder ?? this.isPlaceholder,
  );
  FranchiseLink copyWithCompanion(FranchiseLinkCompanion data) {
    return FranchiseLink(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      rootProvider: data.rootProvider.present
          ? data.rootProvider.value
          : this.rootProvider,
      rootProviderId: data.rootProviderId.present
          ? data.rootProviderId.value
          : this.rootProviderId,
      isPlaceholder: data.isPlaceholder.present
          ? data.isPlaceholder.value
          : this.isPlaceholder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FranchiseLink(')
          ..write('entryId: $entryId, ')
          ..write('rootProvider: $rootProvider, ')
          ..write('rootProviderId: $rootProviderId, ')
          ..write('isPlaceholder: $isPlaceholder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entryId, rootProvider, rootProviderId, isPlaceholder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FranchiseLink &&
          other.entryId == this.entryId &&
          other.rootProvider == this.rootProvider &&
          other.rootProviderId == this.rootProviderId &&
          other.isPlaceholder == this.isPlaceholder);
}

class FranchiseLinkCompanion extends UpdateCompanion<FranchiseLink> {
  final Value<String> entryId;
  final Value<String> rootProvider;
  final Value<int> rootProviderId;
  final Value<bool> isPlaceholder;
  final Value<int> rowid;
  const FranchiseLinkCompanion({
    this.entryId = const Value.absent(),
    this.rootProvider = const Value.absent(),
    this.rootProviderId = const Value.absent(),
    this.isPlaceholder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FranchiseLinkCompanion.insert({
    required String entryId,
    required String rootProvider,
    required int rootProviderId,
    this.isPlaceholder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       rootProvider = Value(rootProvider),
       rootProviderId = Value(rootProviderId);
  static Insertable<FranchiseLink> custom({
    Expression<String>? entryId,
    Expression<String>? rootProvider,
    Expression<int>? rootProviderId,
    Expression<bool>? isPlaceholder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (rootProvider != null) 'root_provider': rootProvider,
      if (rootProviderId != null) 'root_provider_id': rootProviderId,
      if (isPlaceholder != null) 'is_placeholder': isPlaceholder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FranchiseLinkCompanion copyWith({
    Value<String>? entryId,
    Value<String>? rootProvider,
    Value<int>? rootProviderId,
    Value<bool>? isPlaceholder,
    Value<int>? rowid,
  }) {
    return FranchiseLinkCompanion(
      entryId: entryId ?? this.entryId,
      rootProvider: rootProvider ?? this.rootProvider,
      rootProviderId: rootProviderId ?? this.rootProviderId,
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
    if (rootProvider.present) {
      map['root_provider'] = Variable<String>(rootProvider.value);
    }
    if (rootProviderId.present) {
      map['root_provider_id'] = Variable<int>(rootProviderId.value);
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
          ..write('rootProvider: $rootProvider, ')
          ..write('rootProviderId: $rootProviderId, ')
          ..write('isPlaceholder: $isPlaceholder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RelationTable extends Table with TableInfo<RelationTable, Relation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RelationTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [provider, providerId, json, checkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relation';
  @override
  VerificationContext validateIntegrity(
    Insertable<Relation> instance, {
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
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
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
  Relation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Relation(
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}checked_at'],
      )!,
    );
  }

  @override
  RelationTable createAlias(String alias) {
    return RelationTable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(provider, provider_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Relation extends DataClass implements Insertable<Relation> {
  final String provider;
  final int providerId;
  final String json;
  final int checkedAt;
  const Relation({
    required this.provider,
    required this.providerId,
    required this.json,
    required this.checkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['provider_id'] = Variable<int>(providerId);
    map['json'] = Variable<String>(json);
    map['checked_at'] = Variable<int>(checkedAt);
    return map;
  }

  RelationCompanion toCompanion(bool nullToAbsent) {
    return RelationCompanion(
      provider: Value(provider),
      providerId: Value(providerId),
      json: Value(json),
      checkedAt: Value(checkedAt),
    );
  }

  factory Relation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Relation(
      provider: serializer.fromJson<String>(json['provider']),
      providerId: serializer.fromJson<int>(json['provider_id']),
      json: serializer.fromJson<String>(json['json']),
      checkedAt: serializer.fromJson<int>(json['checked_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'provider_id': serializer.toJson<int>(providerId),
      'json': serializer.toJson<String>(json),
      'checked_at': serializer.toJson<int>(checkedAt),
    };
  }

  Relation copyWith({
    String? provider,
    int? providerId,
    String? json,
    int? checkedAt,
  }) => Relation(
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    json: json ?? this.json,
    checkedAt: checkedAt ?? this.checkedAt,
  );
  Relation copyWithCompanion(RelationCompanion data) {
    return Relation(
      provider: data.provider.present ? data.provider.value : this.provider,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      json: data.json.present ? data.json.value : this.json,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Relation(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('json: $json, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(provider, providerId, json, checkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Relation &&
          other.provider == this.provider &&
          other.providerId == this.providerId &&
          other.json == this.json &&
          other.checkedAt == this.checkedAt);
}

class RelationCompanion extends UpdateCompanion<Relation> {
  final Value<String> provider;
  final Value<int> providerId;
  final Value<String> json;
  final Value<int> checkedAt;
  final Value<int> rowid;
  const RelationCompanion({
    this.provider = const Value.absent(),
    this.providerId = const Value.absent(),
    this.json = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelationCompanion.insert({
    required String provider,
    required int providerId,
    required String json,
    required int checkedAt,
    this.rowid = const Value.absent(),
  }) : provider = Value(provider),
       providerId = Value(providerId),
       json = Value(json),
       checkedAt = Value(checkedAt);
  static Insertable<Relation> custom({
    Expression<String>? provider,
    Expression<int>? providerId,
    Expression<String>? json,
    Expression<int>? checkedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (providerId != null) 'provider_id': providerId,
      if (json != null) 'json': json,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelationCompanion copyWith({
    Value<String>? provider,
    Value<int>? providerId,
    Value<String>? json,
    Value<int>? checkedAt,
    Value<int>? rowid,
  }) {
    return RelationCompanion(
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      json: json ?? this.json,
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
    if (json.present) {
      map['json'] = Variable<String>(json.value);
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
    return (StringBuffer('RelationCompanion(')
          ..write('provider: $provider, ')
          ..write('providerId: $providerId, ')
          ..write('json: $json, ')
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
    entryId,
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
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  ScanSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSchedule(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
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
  bool get dontWriteConstraints => true;
}

class ScanSchedule extends DataClass implements Insertable<ScanSchedule> {
  final String entryId;
  final int lastCheckAt;
  final int nextCheckAt;
  final int quietStreak;
  const ScanSchedule({
    required this.entryId,
    required this.lastCheckAt,
    required this.nextCheckAt,
    required this.quietStreak,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['last_check_at'] = Variable<int>(lastCheckAt);
    map['next_check_at'] = Variable<int>(nextCheckAt);
    map['quiet_streak'] = Variable<int>(quietStreak);
    return map;
  }

  ScanScheduleCompanion toCompanion(bool nullToAbsent) {
    return ScanScheduleCompanion(
      entryId: Value(entryId),
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
      entryId: serializer.fromJson<String>(json['entry_id']),
      lastCheckAt: serializer.fromJson<int>(json['last_check_at']),
      nextCheckAt: serializer.fromJson<int>(json['next_check_at']),
      quietStreak: serializer.fromJson<int>(json['quiet_streak']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entry_id': serializer.toJson<String>(entryId),
      'last_check_at': serializer.toJson<int>(lastCheckAt),
      'next_check_at': serializer.toJson<int>(nextCheckAt),
      'quiet_streak': serializer.toJson<int>(quietStreak),
    };
  }

  ScanSchedule copyWith({
    String? entryId,
    int? lastCheckAt,
    int? nextCheckAt,
    int? quietStreak,
  }) => ScanSchedule(
    entryId: entryId ?? this.entryId,
    lastCheckAt: lastCheckAt ?? this.lastCheckAt,
    nextCheckAt: nextCheckAt ?? this.nextCheckAt,
    quietStreak: quietStreak ?? this.quietStreak,
  );
  ScanSchedule copyWithCompanion(ScanScheduleCompanion data) {
    return ScanSchedule(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
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
          ..write('entryId: $entryId, ')
          ..write('lastCheckAt: $lastCheckAt, ')
          ..write('nextCheckAt: $nextCheckAt, ')
          ..write('quietStreak: $quietStreak')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entryId, lastCheckAt, nextCheckAt, quietStreak);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSchedule &&
          other.entryId == this.entryId &&
          other.lastCheckAt == this.lastCheckAt &&
          other.nextCheckAt == this.nextCheckAt &&
          other.quietStreak == this.quietStreak);
}

class ScanScheduleCompanion extends UpdateCompanion<ScanSchedule> {
  final Value<String> entryId;
  final Value<int> lastCheckAt;
  final Value<int> nextCheckAt;
  final Value<int> quietStreak;
  final Value<int> rowid;
  const ScanScheduleCompanion({
    this.entryId = const Value.absent(),
    this.lastCheckAt = const Value.absent(),
    this.nextCheckAt = const Value.absent(),
    this.quietStreak = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanScheduleCompanion.insert({
    required String entryId,
    required int lastCheckAt,
    required int nextCheckAt,
    this.quietStreak = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       lastCheckAt = Value(lastCheckAt),
       nextCheckAt = Value(nextCheckAt);
  static Insertable<ScanSchedule> custom({
    Expression<String>? entryId,
    Expression<int>? lastCheckAt,
    Expression<int>? nextCheckAt,
    Expression<int>? quietStreak,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (lastCheckAt != null) 'last_check_at': lastCheckAt,
      if (nextCheckAt != null) 'next_check_at': nextCheckAt,
      if (quietStreak != null) 'quiet_streak': quietStreak,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanScheduleCompanion copyWith({
    Value<String>? entryId,
    Value<int>? lastCheckAt,
    Value<int>? nextCheckAt,
    Value<int>? quietStreak,
    Value<int>? rowid,
  }) {
    return ScanScheduleCompanion(
      entryId: entryId ?? this.entryId,
      lastCheckAt: lastCheckAt ?? this.lastCheckAt,
      nextCheckAt: nextCheckAt ?? this.nextCheckAt,
      quietStreak: quietStreak ?? this.quietStreak,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
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
          ..write('entryId: $entryId, ')
          ..write('lastCheckAt: $lastCheckAt, ')
          ..write('nextCheckAt: $nextCheckAt, ')
          ..write('quietStreak: $quietStreak, ')
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

abstract class _$DetailsDatabase extends GeneratedDatabase {
  _$DetailsDatabase(QueryExecutor e) : super(e);
  $DetailsDatabaseManager get managers => $DetailsDatabaseManager(this);
  late final DetailTable detail = DetailTable(this);
  late final FranchiseLinkTable franchiseLink = FranchiseLinkTable(this);
  late final Index idxFranchiseRoot = Index(
    'idx_franchise_root',
    'CREATE INDEX idx_franchise_root ON franchise_link (root_provider, root_provider_id)',
  );
  late final RelationTable relation = RelationTable(this);
  late final ScanScheduleTable scanSchedule = ScanScheduleTable(this);
  late final Index idxScanDue = Index(
    'idx_scan_due',
    'CREATE INDEX idx_scan_due ON scan_schedule (next_check_at)',
  );
  late final SearchCache searchCache = SearchCache(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    detail,
    franchiseLink,
    idxFranchiseRoot,
    relation,
    scanSchedule,
    idxScanDue,
    searchCache,
  ];
}

typedef $DetailTableCreateCompanionBuilder = DetailCompanion Function({
  required String provider,
  required int providerId,
  required int fetchedAt,
  required String json,
  Value<int> rowid,
});
typedef $DetailTableUpdateCompanionBuilder = DetailCompanion Function({
  Value<String> provider,
  Value<int> providerId,
  Value<int> fetchedAt,
  Value<String> json,
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

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
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

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
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

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

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
                Value<int> rowid = const Value.absent(),
              }) => DetailCompanion(
                provider: provider,
                providerId: providerId,
                fetchedAt: fetchedAt,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required int providerId,
                required int fetchedAt,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => DetailCompanion.insert(
                provider: provider,
                providerId: providerId,
                fetchedAt: fetchedAt,
                json: json,
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
      required String rootProvider,
      required int rootProviderId,
      Value<bool> isPlaceholder,
      Value<int> rowid,
    });
typedef $FranchiseLinkTableUpdateCompanionBuilder =
    FranchiseLinkCompanion Function({
      Value<String> entryId,
      Value<String> rootProvider,
      Value<int> rootProviderId,
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

  ColumnFilters<String> get rootProvider => $composableBuilder(
    column: $table.rootProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rootProviderId => $composableBuilder(
    column: $table.rootProviderId,
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

  ColumnOrderings<String> get rootProvider => $composableBuilder(
    column: $table.rootProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rootProviderId => $composableBuilder(
    column: $table.rootProviderId,
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

  GeneratedColumn<String> get rootProvider => $composableBuilder(
    column: $table.rootProvider,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rootProviderId => $composableBuilder(
    column: $table.rootProviderId,
    builder: (column) => column,
  );

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
                Value<String> rootProvider = const Value.absent(),
                Value<int> rootProviderId = const Value.absent(),
                Value<bool> isPlaceholder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FranchiseLinkCompanion(
                entryId: entryId,
                rootProvider: rootProvider,
                rootProviderId: rootProviderId,
                isPlaceholder: isPlaceholder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String rootProvider,
                required int rootProviderId,
                Value<bool> isPlaceholder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FranchiseLinkCompanion.insert(
                entryId: entryId,
                rootProvider: rootProvider,
                rootProviderId: rootProviderId,
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
typedef $RelationTableCreateCompanionBuilder = RelationCompanion Function({
  required String provider,
  required int providerId,
  required String json,
  required int checkedAt,
  Value<int> rowid,
});
typedef $RelationTableUpdateCompanionBuilder = RelationCompanion Function({
  Value<String> provider,
  Value<int> providerId,
  Value<String> json,
  Value<int> checkedAt,
  Value<int> rowid,
});

class $RelationTableFilterComposer
    extends Composer<_$DetailsDatabase, RelationTable> {
  $RelationTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $RelationTableOrderingComposer
    extends Composer<_$DetailsDatabase, RelationTable> {
  $RelationTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RelationTableAnnotationComposer
    extends Composer<_$DetailsDatabase, RelationTable> {
  $RelationTableAnnotationComposer({
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

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);
}

class $RelationTableTableManager
    extends
        RootTableManager<
          _$DetailsDatabase,
          RelationTable,
          Relation,
          $RelationTableFilterComposer,
          $RelationTableOrderingComposer,
          $RelationTableAnnotationComposer,
          $RelationTableCreateCompanionBuilder,
          $RelationTableUpdateCompanionBuilder,
          (
            Relation,
            BaseReferences<_$DetailsDatabase, RelationTable, Relation>,
          ),
          Relation,
          PrefetchHooks Function()
        > {
  $RelationTableTableManager(_$DetailsDatabase db, RelationTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RelationTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RelationTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RelationTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> checkedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelationCompanion(
                provider: provider,
                providerId: providerId,
                json: json,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required int providerId,
                required String json,
                required int checkedAt,
                Value<int> rowid = const Value.absent(),
              }) => RelationCompanion.insert(
                provider: provider,
                providerId: providerId,
                json: json,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<RelationTable, Relation>(table),
                  BaseReferences<_$DetailsDatabase, RelationTable, Relation>(
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

typedef $RelationTableProcessedTableManager =
    ProcessedTableManager<
      _$DetailsDatabase,
      RelationTable,
      Relation,
      $RelationTableFilterComposer,
      $RelationTableOrderingComposer,
      $RelationTableAnnotationComposer,
      $RelationTableCreateCompanionBuilder,
      $RelationTableUpdateCompanionBuilder,
      (Relation, BaseReferences<_$DetailsDatabase, RelationTable, Relation>),
      Relation,
      PrefetchHooks Function()
    >;
typedef $ScanScheduleTableCreateCompanionBuilder =
    ScanScheduleCompanion Function({
      required String entryId,
      required int lastCheckAt,
      required int nextCheckAt,
      Value<int> quietStreak,
      Value<int> rowid,
    });
typedef $ScanScheduleTableUpdateCompanionBuilder =
    ScanScheduleCompanion Function({
      Value<String> entryId,
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
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
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
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
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
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

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
                Value<String> entryId = const Value.absent(),
                Value<int> lastCheckAt = const Value.absent(),
                Value<int> nextCheckAt = const Value.absent(),
                Value<int> quietStreak = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanScheduleCompanion(
                entryId: entryId,
                lastCheckAt: lastCheckAt,
                nextCheckAt: nextCheckAt,
                quietStreak: quietStreak,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required int lastCheckAt,
                required int nextCheckAt,
                Value<int> quietStreak = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanScheduleCompanion.insert(
                entryId: entryId,
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

class $DetailsDatabaseManager {
  final _$DetailsDatabase _db;
  $DetailsDatabaseManager(this._db);
  $DetailTableTableManager get detail =>
      $DetailTableTableManager(_db, _db.detail);
  $FranchiseLinkTableTableManager get franchiseLink =>
      $FranchiseLinkTableTableManager(_db, _db.franchiseLink);
  $RelationTableTableManager get relation =>
      $RelationTableTableManager(_db, _db.relation);
  $ScanScheduleTableTableManager get scanSchedule =>
      $ScanScheduleTableTableManager(_db, _db.scanSchedule);
  $SearchCacheTableManager get searchCache =>
      $SearchCacheTableManager(_db, _db.searchCache);
}
