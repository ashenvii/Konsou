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
