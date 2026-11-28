const _japanOffset = Duration(hours: 9);

/// Episodes out so far, or null when it cannot be told; only a tv series still
/// airing is counted. A title not aired yet has 0 out, or null with
/// [zeroBeforeAiring] off, for a count of what can be watched yet.
int? countAiredEpisodes({
  required String? airingStatus,
  required String? mediaType,
  required String? startDate,
  required int? total,
  required DateTime now,
  String? broadcastTime,
  bool zeroBeforeAiring = true,
}) {
  if (airingStatus == 'not_yet_aired') return zeroBeforeAiring ? 0 : null;
  if (airingStatus != 'currently_airing' || mediaType != 'tv') return null;
  final first = _readFirstAiring(startDate, broadcastTime);
  if (first == null) return null;
  if (now.isBefore(first)) return 0;
  final aired = now.difference(first).inDays ~/ 7 + 1;
  return total != null && aired > total ? total : aired;
}

DateTime? _readFirstAiring(String? startDate, String? broadcastTime) {
  // mal gives only a year or a month when the day is not known
  if (startDate == null || startDate.length != 10) return null;
  final day = DateTime.tryParse('${startDate}T${broadcastTime ?? '00:00'}:00Z');
  return day?.subtract(_japanOffset);
}

/// Out so far for a series on the air as MAL lists it inside another answer
/// (a search result, a related title). No broadcast time comes with it, so
/// the day's start stands in. Null for anything not on the air.
int? countAiredInListing(Map<String, dynamic> node, DateTime now) {
  final total = node['num_episodes'];
  return countAiredEpisodes(
    airingStatus: node['status'] as String?,
    mediaType: node['media_type'] as String?,
    startDate: node['start_date'] as String?,
    total: total is int && total > 0 ? total : null,
    now: now,
    zeroBeforeAiring: false,
  );
}
