import 'library_row.dart';

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

/// The small line under a title: "TV · 2023". A part MAL has not given is left
/// out; with neither it is empty.
String typeYearLine(LibraryRow row) => typeYear(row.mediaType, row.startDate);

/// The same line from a media type and a start date as MAL gives them.
String typeYear(String? type, String? date) {
  final parts = [
    if (type != null && type.isNotEmpty) _typeNames[type] ?? _capitalise(type),
    if (date != null && date.length >= 4) date.substring(0, 4),
  ];
  return parts.join(' · ');
}

String _capitalise(String text) => text[0].toUpperCase() + text.substring(1);

/// Episodes watched out of the total. With no known total, only the watched
/// count; with nothing to say, empty.
String progressText(LibraryRow row) =>
    episodeProgress(row.episodesWatched, row.episodes);

String episodeProgress(int watched, int? total) {
  if (total != null && total > 0) return '$watched / $total';
  return watched > 0 ? '$watched' : '';
}

/// "1/2 seasons", only for a franchise with several seasons on the list.
String? seasonsText(LibraryRow row) {
  if (!row.isFranchise) return null;
  return '${row.seasonsDone}/${row.seasonsTotal} seasons';
}

/// The count on a grid card: seasons done of seasons for a franchise, else
/// episodes watched of the total. Empty when there is nothing to count.
String chipCount(LibraryRow row) {
  if (row.isFranchise) return '${row.seasonsDone}/${row.seasonsTotal}';
  return progressText(row).replaceAll(' ', '');
}

/// The title to draw. An entry whose name has not come in yet says so.
String titleText(LibraryRow row) => titleOrLoading(row.name);

String titleOrLoading(String name) => name.isEmpty ? 'Loading details' : name;
