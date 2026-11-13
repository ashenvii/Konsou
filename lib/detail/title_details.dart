import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../data/details_database.dart';
import '../library/title_language.dart';
import '../mal/detail_request.dart';

class ListCounts {
  const ListCounts({
    required this.watching,
    required this.completed,
    required this.onHold,
    required this.dropped,
    required this.planned,
  });

  final int watching;
  final int completed;
  final int onHold;
  final int dropped;
  final int planned;
}

class TitleDetails {
  const TitleDetails({
    required this.malId,
    required this.name,
    required this.isFull,
    required this.fetchedAt,
    this.otherName,
    this.otherNames = const [],
    this.mediaType,
    this.airingStatus,
    this.episodes,
    this.startDate,
    this.endDate,
    this.season,
    this.seasonYear,
    this.broadcastDay,
    this.broadcastTime,
    this.secondsPerEpisode,
    this.source,
    this.rating,
    this.studios = const [],
    this.genres = const [],
    this.synopsis,
    this.background,
    this.nsfw,
    this.score,
    this.rank,
    this.popularity,
    this.listUsers,
    this.listCounts,
  });

  final int malId;

  final String name;

  final String? otherName;

  final List<String> otherNames;

  final bool isFull;
  final int fetchedAt;
  final String? mediaType;
  final String? airingStatus;
  final int? episodes;
  final String? startDate;
  final String? endDate;
  final String? season;
  final int? seasonYear;
  final String? broadcastDay;

  // japan time
  final String? broadcastTime;
  final int? secondsPerEpisode;
  final String? source;
  final String? rating;
  final List<String> studios;
  final List<String> genres;
  final String? synopsis;
  final String? background;
  final String? nsfw;
  final double? score;
  final int? rank;
  final int? popularity;
  final int? listUsers;
  final ListCounts? listCounts;

  double? get completedShare {
    final users = listUsers;
    final counts = listCounts;
    if (users == null || users <= 0 || counts == null) return null;
    return counts.completed / users;
  }

  bool needsFetch(DateTime now) =>
      !isFull ||
      isStale(airingStatus: airingStatus, fetchedAt: fetchedAt, now: now);
}

Future<TitleDetails?> readTitleDetails(
  Databases databases,
  int malId,
  TitleLanguage language,
) async {
  final details = databases.details;
  final row =
      await (details.select(details.detail)..where(
            (row) => row.provider.equals('mal') & row.providerId.equals(malId),
          ))
          .getSingleOrNull();
  return row == null ? null : parseTitleDetails(row, language);
}

TitleDetails parseTitleDetails(Detail row, TitleLanguage language) {
  final json = jsonDecode(row.json) as Map<String, dynamic>;
  final alternative = _map(json['alternative_titles']);
  final names = {
    ...orderTitles(
      language,
      romaji: json['title'] as String?,
      english: alternative['en'] as String?,
      japanese: alternative['ja'] as String?,
    ),
    for (final synonym in _list(alternative['synonyms']))
      if (synonym is String && synonym.isNotEmpty) synonym,
  }.toList();
  final season = _map(json['start_season']);
  final broadcast = _map(json['broadcast']);
  final statistics = _map(json['statistics']);
  final counts = _map(statistics['status']);
  return TitleDetails(
    malId: row.providerId,
    name: names.firstOrNull ?? '',
    otherName: names.elementAtOrNull(1),
    otherNames: names.skip(2).toList(),
    isFull: row.isFull,
    fetchedAt: row.fetchedAt,
    mediaType: row.mediaType,
    airingStatus: row.airingStatus,
    episodes: row.episodes,
    startDate: row.startDate,
    endDate: json['end_date'] as String?,
    season: season['season'] as String?,
    seasonYear: _int(season['year']),
    broadcastDay: broadcast['day_of_the_week'] as String?,
    broadcastTime: broadcast['start_time'] as String?,
    secondsPerEpisode: _positive(json['average_episode_duration']),
    source: json['source'] as String?,
    rating: json['rating'] as String?,
    studios: _readNames(json['studios']),
    genres: _readNames(json['genres']),
    synopsis: _text(json['synopsis']),
    background: _text(json['background']),
    nsfw: row.nsfw,
    score: (json['mean'] as num?)?.toDouble(),
    rank: _int(json['rank']),
    popularity: _int(json['popularity']),
    listUsers:
        _int(statistics['num_list_users']) ?? _int(json['num_list_users']),
    listCounts: counts.isEmpty
        ? null
        : ListCounts(
            watching: _int(counts['watching']) ?? 0,
            completed: _int(counts['completed']) ?? 0,
            onHold: _int(counts['on_hold']) ?? 0,
            dropped: _int(counts['dropped']) ?? 0,
            planned: _int(counts['plan_to_watch']) ?? 0,
          ),
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<Object?> _list(Object? value) => value is List ? value : const [];

// mal sends the status counts as text
int? _int(Object? value) => value is int ? value : int.tryParse('$value');

int? _positive(Object? value) {
  final number = _int(value);
  return number == null || number <= 0 ? null : number;
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

List<String> _readNames(Object? value) => [
  for (final item in _list(value))
    if (_map(item)['name'] case final String name) name,
];
