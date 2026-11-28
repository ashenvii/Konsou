import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../data/details_database.dart';
import '../library/title_language.dart';
import 'theme_song.dart';
import '../library/count_format.dart';

/// How many MAL users have a title in each status.
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

/// A trailer or promotional video on MAL, opened in the browser, with the
/// picture YouTube shows for it.
class TitleVideo {
  const TitleVideo({required this.title, required this.url, this.thumbnail});

  final String title;
  final Uri url;
  final String? thumbnail;
}

/// Another title MAL links to this one: a recommendation with how many
/// people made it, or a manga with how it relates.
class LinkedTitle {
  const LinkedTitle({
    required this.malId,
    required this.name,
    this.pictureUrl,
    this.note,
  });

  final int malId;
  final String name;

  /// Its cover on MAL's image server, for a title with no details saved.
  final String? pictureUrl;

  /// "412 users", "Adaptation".
  final String? note;
}

/// Everything a title page shows about a title, read from details.db.
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
    this.scoredBy,
    this.openings = const [],
    this.endings = const [],
    this.videos = const [],
    this.pictures = const [],
    this.coverUrl,
    this.recommendations = const [],
    this.manga = const [],
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

  /// How many people gave the score.
  final int? scoredBy;

  /// Opening and ending themes, read out of the lines MAL writes for them.
  final List<ThemeSong> openings;
  final List<ThemeSong> endings;
  final List<TitleVideo> videos;

  /// MAL's extra pictures of the title, large, besides the cover.
  final List<String> pictures;

  /// The address of MAL's cover, large, which also shows among [pictures].
  final String? coverUrl;
  final List<LinkedTitle> recommendations;
  final List<LinkedTitle> manga;

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

/// Whether saved details are due a refetch: 3 days airing, 7 not aired, else
/// 180.
bool isStale({
  required String? airingStatus,
  required int fetchedAt,
  required DateTime now,
}) {
  final maxAge = switch (airingStatus) {
    'currently_airing' => const Duration(days: 3),
    'not_yet_aired' => const Duration(days: 7),
    _ => const Duration(days: 180),
  };
  return now.difference(DateTime.fromMillisecondsSinceEpoch(fetchedAt)) >
      maxAge;
}

/// A title's saved details, or null when none are saved.
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

/// Reads a details.db row into [TitleDetails].
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
    scoredBy: _int(json['num_scoring_users']),
    openings: _readThemes(json['opening_themes']),
    endings: _readThemes(json['ending_themes']),
    videos: [
      for (final item in _list(json['videos']))
        if (_map(item) case {
          'title': final String title,
          'url': final String url,
        })
          if (Uri.tryParse(url) case final uri? when uri.hasScheme)
            TitleVideo(
              title: title,
              url: uri,
              thumbnail: _text(_map(item)['thumbnail']),
            ),
    ],
    pictures: [
      for (final item in _list(json['pictures']))
        if (_map(item)['large'] ?? _map(item)['medium'] case final String url)
          url,
    ],
    coverUrl: switch (_map(json['main_picture'])) {
      final picture => (picture['large'] ?? picture['medium']) as String?,
    },
    recommendations: [
      for (final item in _list(json['recommendations']))
        if (_linked(item) case final linked?)
          LinkedTitle(
            malId: linked.malId,
            name: linked.name,
            pictureUrl: linked.pictureUrl,
            note: switch (_int(_map(item)['num_recommendations'])) {
              final count? when count > 0 => formatCountOf(count, 'user'),
              _ => null,
            },
          ),
    ],
    manga: [
      for (final item in _list(json['related_manga']))
        if (_linked(item) case final linked?)
          LinkedTitle(
            malId: linked.malId,
            name: linked.name,
            pictureUrl: linked.pictureUrl,
            note: _map(item)['relation_type_formatted'] as String?,
          ),
    ],
  );
}

List<ThemeSong> _readThemes(Object? value) => [
  for (final (i, item) in _list(value).indexed)
    if (_text(_map(item)['text']) case final text?)
      ThemeSong.parse(text, place: i + 1),
];

// the node of a recommendation or related title
LinkedTitle? _linked(Object? item) {
  final node = _map(_map(item)['node']);
  final id = _int(node['id']);
  final name = _text(node['title']);
  if (id == null || name == null) return null;
  final picture = _map(node['main_picture']);
  return LinkedTitle(
    malId: id,
    name: name,
    pictureUrl: (picture['large'] ?? picture['medium']) as String?,
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
