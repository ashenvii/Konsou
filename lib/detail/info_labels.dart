import '../library/row_labels.dart';
import 'title_details.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A date as MAL gives it ("2023", "2023-09", "2023-09-29") in words.
String? dateWords(String? date) {
  if (date == null || date.length < 4) return null;
  final parts = date.split('-');
  final year = parts[0];
  final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
  final day = parts.length > 2 ? int.tryParse(parts[2]) : null;
  if (month == null || month < 1 || month > 12) return year;
  final name = _monthNames[month - 1];
  return day == null ? '$name $year' : '$day $name $year';
}

/// "29 Sep 2023 to 22 Mar 2024", "29 Sep 2023 to ?" while it airs, or the one
/// date for a title that has no end.
String? airedWords(TitleDetails details) {
  final start = dateWords(details.startDate);
  if (start == null) return null;
  final end = dateWords(details.endDate);
  if (end == start) return start;
  if (end != null) return '$start to $end';
  final airing = details.airingStatus == 'currently_airing';
  return airing ? '$start to ?' : start;
}

String? seasonWords(TitleDetails details) {
  final season = details.season;
  final year = details.seasonYear;
  if (season == null || year == null) return null;
  return '${capitalise(season)} $year';
}

/// "Sundays at 23:00 JST". MAL gives Japan time.
String? broadcastWords(TitleDetails details) {
  final day = details.broadcastDay;
  if (day == null || day.isEmpty) return null;
  final plural = '${capitalise(day)}s';
  final time = details.broadcastTime;
  return time == null || time.isEmpty ? plural : '$plural at $time JST';
}

/// "24 min per episode".
String? durationWords(TitleDetails details) {
  final seconds = details.secondsPerEpisode;
  if (seconds == null) return null;
  final minutes = (seconds / 60).round();
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final text = rest == 0 ? '$hours hr' : '$hours hr $rest min';
    return details.episodes == 1 ? text : '$text per episode';
  }
  return details.episodes == 1 ? '$minutes min' : '$minutes min per episode';
}

const _ratings = {
  'g': 'G, all ages',
  'pg': 'PG, children',
  'pg_13': 'PG-13, teens 13 or older',
  'r': 'R, 17+ (violence and profanity)',
  'r+': 'R+, mild nudity',
  'rx': 'Rx, hentai',
};

String? ratingWords(String? rating) =>
    rating == null || rating.isEmpty ? null : _ratings[rating] ?? rating;

/// "light_novel" as "Light novel".
String? sourceWords(String? source) {
  if (source == null || source.isEmpty) return null;
  return capitalise(source.replaceAll('_', ' '));
}

/// The info block's rows, in order, leaving out whatever MAL did not give.
List<(String, String)> infoRows(TitleDetails details) {
  final type = details.mediaType;
  final episodes = details.episodes;
  final rows = <(String, String?)>[
    ('Type', type == null || type.isEmpty ? null : typeName(type)),
    ('Episodes', episodes == null ? null : '$episodes'),
    ('Aired', airedWords(details)),
    ('Season', seasonWords(details)),
    ('Broadcast', broadcastWords(details)),
    ('Duration', durationWords(details)),
    ('Source', sourceWords(details.source)),
    ('Rating', ratingWords(details.rating)),
    (
      details.studios.length == 1 ? 'Studio' : 'Studios',
      details.studios.isEmpty ? null : details.studios.join(', '),
    ),
    ('Genres', details.genres.isEmpty ? null : details.genres.join(', ')),
  ];
  return [
    for (final (label, value) in rows)
      if (value != null) (label, value),
  ];
}
