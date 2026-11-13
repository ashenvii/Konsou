import '../data/record_database.dart';

const streamerModeKey = 'streamer_mode';

// mal marks a title white, gray (may be unsafe) or black; gray is hidden too
bool isHiddenInStreamerMode({
  required bool streamerMode,
  required String? nsfw,
}) => streamerMode && (nsfw == 'gray' || nsfw == 'black');

Future<bool> readStreamerMode(RecordDatabase record) async {
  final row = await (record.select(
    record.setting,
  )..where((setting) => setting.key.equals(streamerModeKey))).getSingleOrNull();
  return row?.value == 'true';
}
