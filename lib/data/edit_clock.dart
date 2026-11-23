import 'dart:math';

import 'package:drift/drift.dart';

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
  // one statement, so two first calls at once cannot both add a row
  await record.customInsert(
    'INSERT INTO device (device_id) SELECT ? '
    'WHERE NOT EXISTS (SELECT 1 FROM device)',
    variables: [Variable.withString(generateId())],
    updates: {record.device},
  );
  return record.select(record.device).getSingle();
}
