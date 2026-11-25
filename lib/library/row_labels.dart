import 'count_format.dart';
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

String capitalise(String text) => text[0].toUpperCase() + text.substring(1);

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

/// The count in a card's footer. Seasons for a franchise; your progress for a
/// title on your list; the episodes out so far for one still airing that is
/// not ([aired], from `countAiredEpisodes`); otherwise the total.
String formatCardCount({
  required bool onList,
  int watched = 0,
  int? total,
  int? aired,
  int? seasonsDone,
  int? seasonsTotal,
}) {
  if (seasonsTotal != null) return '$seasonsDone / $seasonsTotal seasons';
  if (onList) return formatProgress(watched, total);
  if (aired != null) return 'Ep $aired / ${total ?? '?'}';
  return '${total ?? '?'} ep';
}

/// A Library row's count: its seasons for a franchise, else your progress.
String formatLibraryCount(LibraryRow row) => formatCardCount(
  onList: true,
  watched: row.episodesWatched,
  total: row.episodes,
  seasonsDone: row.seasonsDone,
  seasonsTotal: row.seasonsTotal,
);

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

/// The title to draw. An entry whose name has not come in yet says so.
String formatTitle(String name) => name.isEmpty ? 'Loading details' : name;
