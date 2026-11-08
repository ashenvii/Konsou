import 'dart:math';

import 'generate_id.dart';
import 'record_database.dart';

/// The time an edit is saved with. A device whose clock runs behind still
/// times its edit after everything it has already seen, so the edit wins.
int pickEditTime(int nowMilliseconds, int newestSeenAt) =>
    max(nowMilliseconds, newestSeenAt + 1);

Future<int> readEditTime(RecordDatabase record, DateTime now) async {
  final device = await readDevice(record);
  return pickEditTime(now.millisecondsSinceEpoch, device.newestSeenAt);
}

/// This device's row, made with a new id the first time it is asked for.
Future<Device> readDevice(RecordDatabase record) async {
  final existing = await record.select(record.device).getSingleOrNull();
  if (existing != null) return existing;
  await record
      .into(record.device)
      .insert(DeviceCompanion.insert(deviceId: generateId()));
  return record.select(record.device).getSingle();
}
