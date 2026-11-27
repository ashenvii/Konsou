import '../library/row_labels.dart';
import 'title_details.dart';

/// "29 Sep 2023 to 22 Mar 2024", "29 Sep 2023 to ?" while it airs, or the one
/// date for a title that has no end. Without [days], months and years only,
/// "Sep 2023 to Mar 2024", for a line with little room.
String? formatAired(TitleDetails details, {bool days = true}) {
  String? date(String? value) => formatMalDate(
    !days && value != null && value.length > 7 ? value.substring(0, 7) : value,
  );
  final start = date(details.startDate);
  if (start == null) return null;
  final end = date(details.endDate);
  if (end == start) return start;
  if (end != null) return '$start to $end';
  final airing = details.airingStatus == 'currently_airing';
  return airing ? '$start to ?' : start;
}

String? formatSeason(TitleDetails details) {
  final season = details.season;
  final year = details.seasonYear;
  if (season == null || year == null) return null;
  return '${capitalise(season)} $year';
}

/// "Sundays at 23:00 JST". MAL gives Japan time.
String? formatBroadcast(TitleDetails details) {
  final day = details.broadcastDay;
  if (day == null || day.isEmpty) return null;
  final plural = '${capitalise(day)}s';
  final time = details.broadcastTime;
  return time == null || time.isEmpty ? plural : '$plural at $time JST';
}

/// "24 min per episode".
String? formatDuration(TitleDetails details) {
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

String? formatRating(String? rating) =>
    rating == null || rating.isEmpty ? null : _ratings[rating] ?? rating;

/// "light_novel" as "Light novel".
String? formatSource(String? source) {
  if (source == null || source.isEmpty) return null;
  return capitalise(source.replaceAll('_', ' '));
}

/// The info block's rows, in order, leaving out whatever MAL did not give.
/// The type, season, studios and genres are tags at the top of the page and
/// the episodes a fact there, so they are not said again here.
List<(String, String)> listInfoRows(TitleDetails details) {
  final rows = <(String, String?)>[
    ('Aired', formatAired(details)),
    ('Broadcast', formatBroadcast(details)),
    ('Duration', formatDuration(details)),
    ('Source', formatSource(details.source)),
    ('Rating', formatRating(details.rating)),
  ];
  return [
    for (final (label, value) in rows)
      if (value != null) (label, value),
  ];
}

/// The info block's rows in named groups: when it airs, and where it comes
/// from. A group with nothing in it is left out.
List<(String, List<(String, String)>)> groupInfoRows(TitleDetails details) {
  const groups = [
    ('Airing', {'Aired', 'Broadcast', 'Duration'}),
    ('Origin', {'Source', 'Rating'}),
  ];
  final rows = listInfoRows(details);
  return [
    for (final (name, labels) in groups)
      if (rows.where((row) => labels.contains(row.$1)).toList()
          case final inGroup when inGroup.isNotEmpty)
        (name, inGroup),
  ];
}
