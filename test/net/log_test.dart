import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/net/log.dart';

void main() {
  late Directory folder;
  late File latest;
  late File previous;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('konsou_log_');
    latest = File(
      '${folder.path}${Platform.pathSeparator}logs${Platform.pathSeparator}latest.log',
    );
    previous = File(
      '${folder.path}${Platform.pathSeparator}logs${Platform.pathSeparator}previous.log',
    );
  });

  tearDown(() async {
    await closeLog();
    folder.deleteSync(recursive: true);
  });

  test('a line is time, tag, message', () async {
    await openLog(folder);
    log('mal', 'status 429');
    await closeLog();
    expect(
      latest.readAsLinesSync().single,
      matches(RegExp(r'^\d\d:\d\d:\d\d\.\d{3} mal status 429$')),
    );
  });

  test('the last run is kept as previous.log', () async {
    await openLog(folder);
    log('app', 'first run');
    await closeLog();
    await openLog(folder);
    log('app', 'second run');
    await closeLog();
    expect(previous.readAsStringSync(), contains('first run'));
    expect(latest.readAsStringSync(), contains('second run'));
    expect(latest.readAsStringSync(), isNot(contains('first run')));
  });

  test('nothing is written before the log is opened', () async {
    log('app', 'too early');
    await openLog(folder);
    await closeLog();
    expect(latest.readAsStringSync(), isEmpty);
  });
}
