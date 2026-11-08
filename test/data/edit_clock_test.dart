import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/edit_clock.dart';
import 'package:konsou/data/record_database.dart';

void main() {
  test('an edit is timed by the clock when the clock is ahead', () {
    expect(pickEditTime(5000, 1000), 5000);
  });

  test(
    'an edit is one past the newest time seen when the clock runs behind',
    () {
      expect(pickEditTime(1000, 5000), 5001);
      expect(pickEditTime(5000, 5000), 5001);
    },
  );

  group('on a real record', () {
    late Directory folder;
    late Databases databases;

    setUp(() async {
      folder = Directory.systemTemp.createTempSync('konsou_clock_test');
      databases = await openDatabases(folder);
    });

    tearDown(() async {
      await databases.close();
      folder.deleteSync(recursive: true);
    });

    test('the device row is made once and keeps its id', () async {
      final first = await readDevice(databases.record);
      final second = await readDevice(databases.record);
      expect(first.deviceId, hasLength(32));
      expect(second.deviceId, first.deviceId);
    });

    test(
      'the edit time reads the newest time seen from the device row',
      () async {
        final record = databases.record;
        final device = await readDevice(record);
        await (record.update(record.device)
              ..where((row) => row.deviceId.equals(device.deviceId)))
            .write(const DeviceCompanion(newestSeenAt: Value(9000)));
        final now = DateTime.fromMillisecondsSinceEpoch(2000);
        expect(await readEditTime(record, now), 9001);
      },
    );
  });
}
