const _japanOffset = Duration(hours: 9);

// null when it cannot be told; only a tv series still airing is counted
int? countAiredEpisodes({
  required String? airingStatus,
  required String? mediaType,
  required String? startDate,
  required String? broadcastTime,
  required int? total,
  required DateTime now,
}) {
  if (airingStatus == 'not_yet_aired') return 0;
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
