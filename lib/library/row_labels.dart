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

/// Episodes watched out of the total. With no known total, only the watched
/// count; with nothing to say, empty.
String formatProgress(int watched, int? total) {
  if (total != null && total > 0) return '$watched / $total';
  return watched > 0 ? '$watched' : '';
}

/// "1/2 seasons", only for a franchise with several seasons on the list.
String? formatSeasons(LibraryRow row) {
  if (!row.isFranchise) return null;
  return '${row.seasonsDone}/${row.seasonsTotal} seasons';
}

/// The count on a grid card: seasons done of seasons for a franchise, else
/// episodes watched of the total. Empty when there is nothing to count.
String formatChipCount(LibraryRow row) {
  if (row.isFranchise) return '${row.seasonsDone}/${row.seasonsTotal}';
  return formatProgress(row.episodesWatched, row.episodes).replaceAll(' ', '');
}

/// The title to draw. An entry whose name has not come in yet says so.
String formatTitle(String name) => name.isEmpty ? 'Loading details' : name;
