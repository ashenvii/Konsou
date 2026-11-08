import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../data/edit_clock.dart';
import '../data/record_database.dart';
import '../import/import_old_list.dart';
import '../net/backoff.dart';
import 'drive_client.dart';
import 'google_sign_in.dart';
import 'local_record.dart';
import 'merge_records.dart';
import 'sync_errors.dart';
import 'sync_record.dart';

const recordFileName = 'record.json';

/// The old app's Drive file. Read once when there is no `record.json` yet,
/// never written.
const oldListFileName = 'list.json';

const changeDelay = Duration(seconds: 30);
const closeLimit = Duration(seconds: 3);

enum SyncPhase { off, syncing, synced, waiting, stopped }

enum StopReason { updateKonsou, signInAgain }

class SyncStatus {
  const SyncStatus(this.phase, {this.lastSyncedAt, this.stopReason});

  final SyncPhase phase;
  final DateTime? lastSyncedAt;
  final StopReason? stopReason;
}

/// What one sync moved, for the toast after the first sign-in.
class SyncReport {
  SyncReport({required this.cameIn, required this.wentUp});

  final int cameIn;
  final int wentUp;
}

/// Keeps the record the same on every device through `record.json` in the
/// user's Drive app folder: download when Drive has a new version, merge,
/// write locally, upload when the merge changed something.
class DriveSync {
  DriveSync({
    required this.record,
    required this.drive,
    required this.signIn,
    DateTime Function()? now,
    Timer Function(Duration delay, void Function() callback)? startTimer,
  }) : _now = now ?? DateTime.now,
       _startTimer = startTimer ?? Timer.new;

  final RecordDatabase record;
  final DriveClient drive;
  final GoogleSignIn signIn;
  final DateTime Function() _now;
  final Timer Function(Duration delay, void Function() callback) _startTimer;
  final _backoff = Backoff();
  final _statuses = StreamController<SyncStatus>.broadcast();
  var _status = const SyncStatus(SyncPhase.off);
  Future<SyncReport?>? _running;
  var _runAgain = false;
  Timer? _changeTimer;
  Timer? _retryTimer;

  SyncStatus get status => _status;
  Stream<SyncStatus> get statuses => _statuses.stream;

  /// Syncs now, or once more right after the sync already running.
  Future<SyncReport?> run() {
    final running = _running;
    if (running != null) {
      _runAgain = true;
      return running;
    }
    final next = _runOnce().whenComplete(() {
      _running = null;
      if (_runAgain) {
        _runAgain = false;
        run();
      }
    });
    _running = next;
    return next;
  }

  /// Call after every change to the record; syncs once the changes stop.
  void noteChange() {
    _changeTimer?.cancel();
    _changeTimer = _startTimer(changeDelay, run);
  }

  /// On Close: syncs only when something is not on Drive yet, after any run
  /// already going, and gives up after [closeLimit] so Close always quits.
  Future<void> runBeforeClose() =>
      _syncBeforeClose().timeout(closeLimit, onTimeout: () {});

  Future<void> _syncBeforeClose() async {
    _changeTimer?.cancel();
    _retryTimer?.cancel();
    await _running;
    if (_status.phase == SyncPhase.stopped || !await signIn.isSignedIn()) {
      return;
    }
    final device = await readDevice(record);
    final local = await readLocalRecord(record);
    if (_hashText(local.toJson()) == device.driveHash) return;
    await run();
  }

  void dispose() {
    _changeTimer?.cancel();
    _retryTimer?.cancel();
    _statuses.close();
  }

  Future<SyncReport?> _runOnce() async {
    _retryTimer?.cancel();
    if (!await signIn.isSignedIn()) {
      _setStatus(const SyncStatus(SyncPhase.off));
      return null;
    }
    _setStatus(
      SyncStatus(SyncPhase.syncing, lastSyncedAt: _status.lastSyncedAt),
    );
    try {
      final report = await _syncWithDrive();
      _backoff.reset();
      return report;
    } on NewerFormat {
      _stop(StopReason.updateKonsou);
    } on SignInNeeded {
      _stop(StopReason.signInAgain);
    } on DriveUnavailable {
      _wait();
    } catch (_) {
      // anything else must not leave the icon on syncing; try again later
      _wait();
    }
    return null;
  }

  Future<SyncReport> _syncWithDrive() async {
    final device = await readDevice(record);
    final file = await drive.findFile(recordFileName);
    // the id as well as the version: another account or a recreated file
    // can sit at the same version number
    final fileVersion = file == null ? null : '${file.id} ${file.version}';
    String? remoteText;
    SyncRecord? remote;
    if (file == null) {
      remote = await _readOldList();
    } else if (fileVersion != device.driveVersion) {
      remoteText = await drive.downloadFile(file.id);
      remote = _readRemote(remoteText);
    }

    SyncReport report;
    try {
      report = await _mergeIntoRecord(remote, isNewFile: file == null);
    } catch (_) {
      if (remote == null) rethrow;
      // a copy that reads but cannot be merged or saved is damaged too
      remote = null;
      report = await _mergeIntoRecord(null, isNewFile: file == null);
    }

    final text = (await readLocalRecord(record)).toJson();
    final hash = _hashText(text);
    final driveHash = remoteText == null
        ? device.driveHash
        : _hashText(remoteText);
    var newVersion = fileVersion;
    if (file == null) {
      final created = await drive.createFile(recordFileName, text);
      newVersion = '${created.id} ${created.version}';
    } else if (hash != driveHash) {
      final updated = await drive.updateFile(file.id, text);
      newVersion = '${updated.id} ${updated.version}';
    }

    final syncedAt = _now();
    await _updateDevice(
      device,
      DeviceCompanion(
        driveVersion: Value(newVersion),
        driveHash: Value(hash),
        lastSyncedAt: Value(syncedAt.millisecondsSinceEpoch),
      ),
    );
    _setStatus(SyncStatus(SyncPhase.synced, lastSyncedAt: syncedAt));
    return report;
  }

  /// Merges [remote] into `konsou.db` in one transaction, together with the
  /// newest time seen, so the edit clock is right even if the upload fails.
  Future<SyncReport> _mergeIntoRecord(
    SyncRecord? remote, {
    required bool isNewFile,
  }) => record.transaction(() async {
    final device = await readDevice(record);
    final local = await readLocalRecord(record);
    final merged = remote == null ? local : mergeRecords(local, remote);
    if (merged.toJson() != local.toJson()) {
      await writeLocalRecord(record, merged);
    }
    await _updateDevice(
      device,
      DeviceCompanion(
        newestSeenAt: Value(max(device.newestSeenAt, merged.newestTime)),
      ),
    );
    final localIds = _readEntryIds(local);
    return SyncReport(
      cameIn: _readEntryIds(merged).difference(localIds).length,
      wentUp: isNewFile || remote != null
          ? localIds.difference(_readEntryIds(remote ?? SyncRecord())).length
          : 0,
    );
  });

  Future<SyncRecord?> _readOldList() async {
    final old = await drive.findFile(oldListFileName);
    if (old == null) return null;
    try {
      return await readOldDriveList(await drive.downloadFile(old.id));
    } on ImportRefused {
      return null;
    }
  }

  /// A damaged copy reads as nothing, so this device's record replaces it.
  SyncRecord? _readRemote(String text) {
    try {
      return SyncRecord.fromJson(text);
    } on FormatException {
      return null;
    }
  }

  Future<void> _updateDevice(Device device, DeviceCompanion changes) =>
      (record.update(
        record.device,
      )..where((row) => row.deviceId.equals(device.deviceId))).write(changes);

  void _stop(StopReason reason) => _setStatus(
    SyncStatus(
      SyncPhase.stopped,
      lastSyncedAt: _status.lastSyncedAt,
      stopReason: reason,
    ),
  );

  void _wait() {
    _setStatus(
      SyncStatus(SyncPhase.waiting, lastSyncedAt: _status.lastSyncedAt),
    );
    _retryTimer = _startTimer(_backoff.next(), run);
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    if (!_statuses.isClosed) _statuses.add(status);
  }
}

/// The old app's `list.json` as a record, by importing it into a scratch
/// pair of databases. Its ids come out as `legacy-<anilist id>`, the same as
/// on any device that imported the same list, so nothing doubles.
Future<SyncRecord> readOldDriveList(String json) async {
  final folder = Directory.systemTemp.createTempSync('konsou_old_list');
  final scratch = await openDatabases(folder);
  try {
    await importDriveList(json, scratch);
    return await readLocalRecord(scratch.record);
  } finally {
    await scratch.close();
    folder.deleteSync(recursive: true);
  }
}

Set<Object?> _readEntryIds(SyncRecord record) => {
  for (final entry in record.entries) entry['entry_id'],
};

String _hashText(String text) => sha256.convert(utf8.encode(text)).toString();
