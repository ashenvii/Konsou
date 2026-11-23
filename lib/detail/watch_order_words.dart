import '../library/entry_status.dart';
import '../library/row_labels.dart';
import 'info_labels.dart';
import 'watch_order.dart';

/// "3 of 5 on your list · 59 of 87 episodes watched".
String watchOrderSummary(WatchOrder order) {
  final total = order.episodesTotal;
  return '${order.onList} of ${order.rows.length} on your list'
      '${total > 0 ? ' · ${order.episodesWatched} of $total episodes watched' : ''}';
}

/// The state in words, for a screen reader: the square has no text.
String watchOrderStateLabel(WatchOrderRow row) {
  if (row.isLoadingDetails) return 'Loading details';
  final status = row.status;
  if (status != null) return status.label;
  return row.isNotAired ? 'Not aired yet' : 'Not on your list';
}

/// The line under a title's name: the status in words with its episodes, live
/// ones in full ink. A finished title says only its episodes.
(String, bool) watchOrderState(WatchOrderRow row) {
  if (row.isLoadingDetails) return ('', false);
  final status = row.status;
  final total = row.episodes;
  final episodes = total == null ? null : '$total ep';
  String withEpisodes(String text) =>
      episodes == null ? text : '$text · $episodes';
  if (status == null) {
    return (
      row.isNotAired ? 'Not aired yet' : withEpisodes('Not on your list'),
      false,
    );
  }
  if (status == EntryStatus.completed) {
    return (episodes ?? status.label, false);
  }
  final live =
      status == EntryStatus.watching || status == EntryStatus.rewatching;
  final progress = formatProgress(row.episodesWatched, total);
  // a title not started shows its total, not "0 / 12"
  if (progress.isNotEmpty && (live || row.episodesWatched > 0)) {
    return ('${status.label} $progress', live);
  }
  return (withEpisodes(status.label), false);
}

/// When the title came out: the year, or the whole date for a title still to
/// air.
String watchOrderWhen(WatchOrderRow row) {
  final date = row.startDate;
  if (row.isNotAired) return formatMalDate(date) ?? 'TBA';
  return date != null && date.length >= 4 ? date.substring(0, 4) : '';
}

/// "2018 · TV": when it came out and what it is.
String watchOrderMeta(WatchOrderRow row) {
  final type = row.mediaType;
  return [
    watchOrderWhen(row),
    if (type != null && type.isNotEmpty) formatType(type),
  ].where((part) => part.isNotEmpty).join(' · ');
}
