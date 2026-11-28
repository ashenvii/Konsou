import 'count_format.dart';
import 'entry_status.dart';
import 'library_row.dart';

/// The word for a MAL media type: "TV", "Movie", "TV Special".
String formatType(String type) => _typeNames[type] ?? capitalise(type);

const _typeNames = {
  'tv': 'TV',
  'movie': 'Movie',
  'ova': 'OVA',
  'ona': 'ONA',
  'special': 'Special',
  'tv_special': 'TV Special',
  'cm': 'CM',
  'pv': 'PV',
  'music': 'Music',
};

/// The small line under a title, from a media type and a start date as MAL
/// gives them: "TV · 2023". A part MAL has not given is left out; with neither
/// it is empty.
String formatTypeYear(String? type, String? date) {
  final parts = [
    if (type != null && type.isNotEmpty) formatType(type),
    if (date != null && date.length >= 4) date.substring(0, 4),
  ];
  return parts.join(' · ');
}

/// The line under a row's name: "TV · 2023", or the whole date for a title
/// not aired yet ("Movie · 12 Jan 2027"), "?" where MAL gives no date.
String formatTypeWhen(String? type, String? date, {required bool notAired}) => [
  if (type != null && type.isNotEmpty) formatType(type),
  formatCardWhen(date, notAired: notAired),
].join(' · ');

/// The text with its first letter in upper case.
String capitalise(String text) => text[0].toUpperCase() + text.substring(1);

/// A count of episodes in words, such as 12 episodes.
String formatEpisodes(int n) => formatCountOf(n, 'episode');

/// A month's name, 1 for January. Short gives the first three letters.
String formatMonth(int month, {bool short = false}) {
  final name = _monthNames[month - 1];
  return short ? name.substring(0, 3) : name;
}

/// "14 Nov 2026".
String formatDate(DateTime date) =>
    '${date.day} ${formatMonth(date.month, short: true)} ${date.year}';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// A date as MAL gives it, as much as is known: "29 Sep 2023", "Sep 2023",
/// "2023". Null when there is none.
String? formatMalDate(String? date) {
  if (date == null || date.length < 4) return null;
  final parts = date.split('-');
  final year = parts[0];
  final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
  final day = parts.length > 2 ? int.tryParse(parts[2]) : null;
  if (month == null || month < 1 || month > 12) return year;
  final name = formatMonth(month, short: true);
  return day == null ? '$name $year' : '$day $name $year';
}

/// Episodes watched out of the total, "?" while MAL has no total.
String formatProgress(int watched, int? total) =>
    '$watched / ${total != null && total > 0 ? total : '?'}';

/// What a count display reads: [done] out of [total] ("?" while MAL has
/// none), then [unit]: none for your episodes, "aired" for the episodes out so far of a title airing that is not on your
/// list (`countAiredEpisodes`), "ep" for a total alone.
typedef CardCount = ({String? done, String total, String? unit});

/// A card's count: watched of total on the list, else aired or the total.
CardCount countCard({
  required bool onList,
  int watched = 0,
  int? total,
  int? aired,
}) {
  final known = total != null && total > 0 ? '$total' : '?';
  if (onList) return (done: '$watched', total: known, unit: null);
  if (aired != null) return (done: '$aired', total: known, unit: 'aired');
  return (done: null, total: known, unit: 'ep');
}

/// A Library row's count: your episodes of the season it stands for.
CardCount countLibraryRow(LibraryRow row) =>
    countCard(onList: true, watched: row.episodesWatched, total: row.episodes);

/// MAL's score as MAL writes it, "?" when too few users have scored it.
String formatMalScore(double? score) => score?.toStringAsFixed(2) ?? '?';

/// When a title came out: the year, or the whole date for a title still to
/// air, "?" with no date.
String formatCardWhen(String? startDate, {required bool notAired}) {
  if (notAired) return formatMalDate(startDate) ?? '?';
  return startDate != null && startDate.length >= 4
      ? startDate.substring(0, 4)
      : '?';
}

/// What a title says, aloud or drawn, while its details come in.
const loadingDetails = 'Loading details';

/// The title to draw. An entry whose name has not come in yet says so.
String formatTitle(String name) => name.isEmpty ? loadingDetails : name;

/// Your progress on a Library row in words, for its quick panel: "Episode 4
/// of 28", "All 12 episodes", "28 episodes" before you start; a franchise
/// names the season the row stands for among those on your list, "Season 2
/// of 3", or "All 3 seasons" once all are done.
String formatPanelProgress(LibraryRow row) {
  final season = row.seasonNumber;
  final seasons = row.seasonsTotal;
  if (season != null && seasons != null) {
    return row.allSeasonsDone
        ? 'All $seasons seasons'
        : 'Season $season of $seasons';
  }
  final total = row.episodes;
  final known = total != null && total > 0;
  if (row.status == EntryStatus.completed) {
    return known ? 'All $total episodes' : EntryStatus.completed.label;
  }
  if (row.episodesWatched == 0 && row.status == EntryStatus.planned) {
    return known ? '$total episodes' : '? episodes';
  }
  return 'Episode ${row.episodesWatched} of ${known ? total : '?'}';
}
