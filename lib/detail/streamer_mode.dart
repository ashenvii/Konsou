import '../data/record_database.dart';

/// Setting key for streamer mode.
const streamerModeKey = 'streamer_mode';

/// Whether streamer mode hides a title. MAL marks titles white, gray (may be
/// unsafe) or black; gray is hidden too.
bool isHiddenInStreamerMode({
  required bool streamerMode,
  required String? nsfw,
}) => streamerMode && (nsfw == 'gray' || nsfw == 'black');

/// Whether streamer mode is on.
Future<bool> readStreamerMode(RecordDatabase record) async =>
    await record.readSetting(streamerModeKey) == 'true';
