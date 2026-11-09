import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/edit_clock.dart';
import 'package:konsou/library/entry_edits.dart';
import 'package:konsou/sync/drive_client.dart';
import 'package:konsou/sync/drive_sync.dart';
import 'package:konsou/sync/google_sign_in.dart';
import 'package:konsou/sync/local_record.dart';
import 'package:konsou/sync/sync_record.dart';

import '../support/fake_google.dart';
import '../support/sync_rows.dart';

final _now = DateTime.utc(2026, 11, 8, 12);

/// One device: its own databases and tokens, talking to the shared fake Drive.
class FakeDevice {
  FakeDevice(this.databases, this.sync, this.timers);

  final Databases databases;
  final DriveSync sync;
  final List<(Duration, void Function())> timers;

  Future<SyncRecord> readRecord() => readLocalRecord(databases.record);

  Future<void> save(SyncRecord changed) =>
      writeLocalRecord(databases.record, changed);
}

void main() {
  late FakeGoogle google;
  final folders = <Directory>[];
  final devices = <FakeDevice>[];

  Future<FakeDevice> buildDevice({bool signedIn = true}) async {
    final folder = Directory.systemTemp.createTempSync('konsou_sync_test');
    folders.add(folder);
    final databases = await openDatabases(folder);
    final store = MemoryTokenStore();
    if (signedIn) {
      store.tokens = GoogleTokens(
        accessToken: google.validToken,
        refreshToken: 'refresh-1',
        expiresAt: _now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        email: 'owner@example.com',
      );
    }
    final signIn = GoogleSignIn(
      clientId: 'client',
      clientSecret: 'secret',
      client: google.client,
      store: store,
      openBrowser: (_) async {},
      now: () => _now,
    );
    final timers = <(Duration, void Function())>[];
    final device = FakeDevice(
      databases,
      DriveSync(
        record: databases.record,
        drive: DriveClient(
          client: google.client,
          accessToken: signIn.accessToken,
        ),
        signIn: signIn,
        now: () => _now,
        startTimer: (delay, callback) {
          timers.add((delay, callback));
          return Timer(const Duration(days: 1), () {});
        },
      ),
      timers,
    );
    devices.add(device);
    return device;
  }

  setUp(() => google = FakeGoogle());

  tearDown(() async {
    for (final device in devices) {
      device.sync.dispose();
      await device.databases.close();
    }
    for (final folder in folders) {
      folder.deleteSync(recursive: true);
    }
    devices.clear();
    folders.clear();
  });

  test('the first sync uploads the record, the next one with no change sends nothing', () async {
    final pc = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('a', malId: 1)]));

    final report = await pc.sync.run();
    expect(report!.wentUp, 1);
    expect(pc.sync.status.phase, SyncPhase.synced);
    expect(
      google.file(recordFileName)!.content,
      (await pc.readRecord()).toJson(),
    );
    expect(google.file(recordFileName)!.content, isNot(contains('"name":"')));

    google.asked.clear();
    await pc.sync.run();
    expect(google.uploads, 1);
    expect(
      google.asked.where(
        (a) => a.startsWith('GET www.googleapis.com/drive/v3/files/'),
      ),
      isEmpty,
    );
  });

  test(
    'the same title added on two devices ends as one entry on both',
    () async {
      final pc = await buildDevice();
      final phone = await buildDevice();
      await pc.save(
        SyncRecord(entries: [buildEntry('pc-id', addedAt: 100, malId: 52991)]),
      );
      await phone.save(
        SyncRecord(
          entries: [
            buildEntry(
              'phone-id',
              addedAt: 50,
              malId: 52991,
              episodes: 3,
              progressAt: 60,
            ),
          ],
        ),
      );

      await pc.sync.run();
      await phone.sync.run();
      await pc.sync.run();

      final onPc = await pc.readRecord();
      final onPhone = await phone.readRecord();
      expect(onPc.toJson(), onPhone.toJson());
      expect(onPc.entries.single['entry_id'], 'phone-id');
      expect(onPc.entries.single['episodes_watched'], 3);
    },
  );

  test(
    'edits on both devices meet, each group keeping the later one',
    () async {
      final pc = await buildDevice();
      final phone = await buildDevice();
      await pc.save(SyncRecord(entries: [buildEntry('x', malId: 1)]));
      await pc.sync.run();
      await phone.sync.run();

      await pc.save(
        SyncRecord(
          entries: [buildEntry('x', malId: 1, notes: 'pc', notesAt: 500)],
        ),
      );
      await phone.save(
        SyncRecord(
          entries: [buildEntry('x', malId: 1, episodes: 5, progressAt: 400)],
        ),
      );
      await pc.sync.run();
      await phone.sync.run();
      await pc.sync.run();

      final onPc = await pc.readRecord();
      expect(onPc.toJson(), (await phone.readRecord()).toJson());
      expect(onPc.entries.single['notes'], 'pc');
      expect(onPc.entries.single['episodes_watched'], 5);
    },
  );

  test(
    'a phone whose clock runs behind still wins with its later edit',
    () async {
      final pc = await buildDevice();
      final phone = await buildDevice();
      await pc.save(SyncRecord(entries: [buildEntry('x', progressAt: 9000)]));
      await pc.sync.run();
      await phone.sync.run();

      final behind = DateTime.fromMillisecondsSinceEpoch(1000);
      final editAt = await readEditTime(phone.databases.record, behind);
      await phone.save(
        SyncRecord(entries: [buildEntry('x', episodes: 2, progressAt: editAt)]),
      );
      await phone.sync.run();
      await pc.sync.run();

      expect((await pc.readRecord()).entries.single['episodes_watched'], 2);
    },
  );

  test(
    'a removal on one device clears the other, finished watches too',
    () async {
      final pc = await buildDevice();
      final phone = await buildDevice();
      await pc.save(
        SyncRecord(
          entries: [buildEntry('a', malId: 1), buildEntry('b', malId: 2)],
          completions: [buildCompletion('a', 0, 5), buildCompletion('b', 0, 5)],
          alerts: [buildAlert('a', 9)],
        ),
      );
      await pc.sync.run();
      await phone.sync.run();
      expect((await phone.readRecord()).completions, hasLength(2));

      await EntryEdits(databases: pc.databases, now: () => _now).remove(['a']);
      await pc.sync.run();
      await phone.sync.run();

      final onPhone = await phone.readRecord();
      expect(onPhone.entries.map((row) => row['entry_id']), ['b']);
      expect(onPhone.completions.map((row) => row['entry_id']), ['b']);
      expect(onPhone.alerts, isEmpty);
      expect(onPhone.deletions.map((row) => row['entry_id']), ['a']);
    },
  );

  test("the old app's list.json is merged in and never written", () async {
    const oldList =
        '{"version": 1, "exported_at": 1, "entries": ['
        '{"anilist_id": 21, "mal_id": 21, "title_romaji": "ONE PIECE", '
        '"status": "watching", "episodes_watched": 235, "added_at": 1669585154282, '
        '"updated_at": 1793390531000}]}';
    google.addFile(oldListFileName, oldList);
    final pc = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('new', malId: 5)]));

    final report = await pc.sync.run();

    expect(report!.cameIn, 1);
    final ids = (await pc.readRecord()).entries.map(
      (entry) => entry['entry_id'],
    );
    expect(ids, ['legacy-21', 'new']);
    expect(google.file(oldListFileName)!.content, oldList);
    expect(google.file(recordFileName), isNotNull);
  });

  test('a file from a newer Konsou stops sync and is left alone', () async {
    final newer = jsonEncode({'format': recordFormat + 1, 'entries': []});
    google.addFile(recordFileName, newer);
    final pc = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('a')]));

    await pc.sync.run();

    expect(pc.sync.status.phase, SyncPhase.stopped);
    expect(pc.sync.status.stopReason, StopReason.updateKonsou);
    expect(google.file(recordFileName)!.content, newer);
    expect((await pc.readRecord()).entries, hasLength(1));
  });

  test("a damaged file on Drive is replaced by this device's record", () async {
    google.addFile(recordFileName, '{"format": 1, "entries": [');
    final pc = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('a')]));

    await pc.sync.run();

    expect(pc.sync.status.phase, SyncPhase.synced);
    expect(
      google.file(recordFileName)!.content,
      (await pc.readRecord()).toJson(),
    );
  });

  test('a revoked sign-in stops sync until the user signs in again', () async {
    final pc = await buildDevice();
    google.validToken = 'only-after-refresh';
    google.refreshAnswer = 400;

    await pc.sync.run();

    expect(pc.sync.status.phase, SyncPhase.stopped);
    expect(pc.sync.status.stopReason, StopReason.signInAgain);
  });

  test('Drive not answering waits and retries on the backoff', () async {
    final pc = await buildDevice();
    google.driveFailure = 503;

    await pc.sync.run();
    expect(pc.sync.status.phase, SyncPhase.waiting);
    expect(pc.timers.last.$1, const Duration(seconds: 5));

    await pc.sync.run();
    expect(pc.timers.last.$1, const Duration(seconds: 10));

    google.driveFailure = null;
    final synced = pc.sync.statuses.firstWhere(
      (status) => status.phase == SyncPhase.synced,
    );
    pc.timers.last.$2();
    await synced;
  });

  test('not signed in is off and asks Drive nothing', () async {
    final pc = await buildDevice(signedIn: false);
    await pc.sync.run();
    expect(pc.sync.status.phase, SyncPhase.off);
    expect(google.asked, isEmpty);
  });

  test('a change syncs 30 seconds after the last one', () async {
    final pc = await buildDevice();
    pc.sync.noteChange();
    pc.sync.noteChange();
    expect(pc.timers.map((timer) => timer.$1), [changeDelay, changeDelay]);
  });

  test('Close uploads only what is not on Drive yet', () async {
    final pc = await buildDevice();
    await pc.sync.run();
    expect(google.uploads, 1);

    await pc.sync.runBeforeClose();
    expect(google.uploads, 1);

    await pc.save(SyncRecord(entries: [buildEntry('late', malId: 3)]));
    await pc.sync.runBeforeClose();
    expect(google.uploads, 2);
  });

  test('a new file at the same version number is still downloaded', () async {
    final pc = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('a', malId: 1)]));
    await pc.sync.run();

    // another account, or drive's app data deleted and made again: version 1
    google.files.clear();
    google.addFile(
      recordFileName,
      SyncRecord(entries: [buildEntry('b', malId: 2)]).toJson(),
    );
    await pc.sync.run();

    final ids = (await pc.readRecord()).entries.map((e) => e['entry_id']);
    expect(ids, ['a', 'b']);
    expect(google.file(recordFileName)!.content, contains('"a"'));
  });

  test('a file that reads but cannot be saved is replaced too', () async {
    final broken = SyncRecord(entries: [buildEntry('x', score: 11, scoreAt: 5)])
        .toJson();
    google.addFile(recordFileName, broken);
    final pc = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('a')]));

    await pc.sync.run();

    expect(pc.sync.status.phase, SyncPhase.synced);
    expect(google.file(recordFileName)!.content, isNot(broken));
    expect((await pc.readRecord()).entries.single['entry_id'], 'a');
  });

  test('the newest time seen is kept even when the upload fails', () async {
    final pc = await buildDevice();
    final phone = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('x', progressAt: 9000)]));
    await pc.sync.run();
    await phone.save(SyncRecord(entries: [buildEntry('y', progressAt: 10)]));

    google.uploadFailure = 503;
    await phone.sync.run();

    expect(phone.sync.status.phase, SyncPhase.waiting);
    final behind = DateTime.fromMillisecondsSinceEpoch(1000);
    expect(await readEditTime(phone.databases.record, behind), 9001);
  });

  test(
    'when two devices each made the file, both settle on the oldest',
    () async {
      google.addFile(
        recordFileName,
        SyncRecord(entries: [buildEntry('first')]).toJson(),
      );
      google.addFile(
        recordFileName,
        SyncRecord(entries: [buildEntry('second')]).toJson(),
      );
      final pc = await buildDevice();
      await pc.save(SyncRecord(entries: [buildEntry('mine')]));

      await pc.sync.run();

      expect(google.files['id-1']!.content, contains('"first"'));
      expect(google.files['id-1']!.content, contains('"mine"'));
      expect(google.files['id-2']!.content, isNot(contains('"first"')));
      expect(
        google.asked,
        contains('PATCH www.googleapis.com/upload/drive/v3/files/id-1'),
      );
    },
  );

  test('an old list.json that is not a list is passed over', () async {
    google.addFile(oldListFileName, '[1, 2, 3]');
    final pc = await buildDevice();
    await pc.save(SyncRecord(entries: [buildEntry('a')]));

    await pc.sync.run();

    expect(pc.sync.status.phase, SyncPhase.synced);
    expect(google.file(recordFileName), isNotNull);
  });
}
