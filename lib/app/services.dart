import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../covers/cover_store.dart';
import '../covers/cover_trickle.dart';
import '../data/databases.dart';
import '../mal/detail_request.dart';
import '../mal/franchise_scan.dart';
import '../mal/matching.dart';
import '../mal/request_gate.dart';
import '../mal/search_request.dart';
import '../mal/trickle.dart';
import '../net/log.dart';
import '../sync/drive_client.dart';
import '../sync/drive_sync.dart';
import '../sync/google_sign_in.dart';
import 'keys.dart';
import 'load_progress.dart';

class Services {
  Services({
    required this.databases,
    required this.keys,
    required this.coversFolder,
    required http.Client client,
    required TokenStore tokenStore,
    required this.openBrowser,
    RequestGate? gate,
  }) {
    if (keys.hasGoogle) {
      final signIn = GoogleSignIn(
        clientId: keys.googleClientId,
        clientSecret: keys.googleClientSecret,
        client: client,
        store: tokenStore,
        openBrowser: openBrowser,
      );
      sync = DriveSync(
        record: databases.record,
        drive: DriveClient(client: client, accessToken: signIn.accessToken),
        signIn: signIn,
      );
      this.signIn = signIn;
    }
    if (keys.hasMal) {
      final requestGate = _malGate = gate ?? RequestGate();
      final detailRequest = this.detailRequest = DetailRequest(
        clientId: keys.malClientId,
        client: client,
        gate: requestGate,
        details: databases.details,
      );
      matching = Matching(
        databases: databases,
        searchRequest: SearchRequest(
          clientId: keys.malClientId,
          client: client,
          gate: requestGate,
        ),
        detailRequest: detailRequest,
      );
      trickle = Trickle(
        record: databases.record,
        detailRequest: detailRequest,
        matching: matching!,
        onProgress: () {
          notifyDataChanged();
          _countProgress();
        },
      );
      coverStore = CoverStore(
        databases: databases,
        folder: coversFolder,
        client: client,
        // the image server is not the API: its own, faster gate
        gate: _coverGate = RequestGate(name: 'covers', gap: coverRequestGap),
        onSaved: _coverSaved.add,
      );
      // a saved cover reaches the screen through coverSaved, not a reload
      coverTrickle = CoverTrickle(
        databases: databases,
        store: coverStore!,
        onProgress: _countProgress,
      );
      scan = FranchiseScan(databases: databases, detailRequest: detailRequest);
    }
  }

  final Databases databases;
  final Keys keys;
  final Directory coversFolder;

  /// Opens a page in the user's browser: sign-in, and a title's trailers.
  final Future<void> Function(Uri url) openBrowser;
  GoogleSignIn? signIn;
  DriveSync? sync;
  DetailRequest? detailRequest;
  Matching? matching;
  Trickle? trickle;
  CoverStore? coverStore;
  CoverTrickle? coverTrickle;
  FranchiseScan? scan;
  var _stopped = false;
  final _dataChanged = StreamController<void>.broadcast();
  final _coverSaved = StreamController<int>.broadcast();
  final _screenDataChanged = StreamController<void>.broadcast();

  Stream<void> get dataChanged => _dataChanged.stream;

  void notifyDataChanged() => _dataChanged.add(null);

  Stream<void> get screenDataChanged => _screenDataChanged.stream;

  void notifyScreenDataChanged() => _screenDataChanged.add(null);

  Stream<int> get coverSaved => _coverSaved.stream;

  Future<void> start() => _whileBusy(() async {
    await sync?.run();
    notifyDataChanged();
    if (_stopped) return;
    await _loadAll(redoDetails: true, redoCovers: true);
    if (_stopped) return;
    log('scan', 'start');
    await scan?.run();
    log('scan', 'finished');
    notifyDataChanged();
  });

  RequestGate? _malGate;
  RequestGate? _coverGate;
  final _loadProgress = StreamController<LoadProgress>.broadcast();
  var _progress = const LoadProgress();
  LoadJob? _loading;
  var _loadedAny = false;

  /// What is loading in the background now, for the wordmark.
  LoadProgress get progress => _progress;

  Stream<LoadProgress> get loadProgress => _loadProgress.stream;

  // details, then covers; the wordmark hears about a job only when it has work
  Future<void> _loadAll({
    required bool redoDetails,
    required bool redoCovers,
  }) async {
    final details = trickle;
    final covers = coverTrickle;
    if (redoDetails && details != null) {
      await _load(LoadJob.details, details.run);
    }
    if (_stopped) return;
    if (redoCovers && covers != null) await _load(LoadJob.covers, covers.run);
    if (_stopped || !_loadedAny) return;
    _loadedAny = false;
    _show(const LoadProgress(finished: true));
  }

  Future<void> _load(LoadJob job, Future<void> Function() run) async {
    final counts = await readLoadCounts(databases);
    final count = job == LoadJob.details ? counts.details : counts.covers;
    if (count.done < count.total) {
      _loading = job;
      _loadedAny = true;
      _showCounts(job, counts);
    }
    log('load', '${job.name} start, ${count.done} of ${count.total} done');
    try {
      await run();
    } finally {
      _loading = null;
      log('load', '${job.name} ended');
    }
  }

  Future<void> _countProgress() async {
    final job = _loading;
    if (job == null) return;
    final counts = await readLoadCounts(databases);
    // the job may have ended while the counts were read
    if (_loading == job) _showCounts(job, counts);
  }

  void _showCounts(
    LoadJob job,
    ({LoadCount details, LoadCount covers}) counts,
  ) {
    final gate = job == LoadJob.details ? _malGate : _coverGate;
    _show(
      LoadProgress(
        job: job,
        waiting: gate?.backingOff ?? false,
        details: counts.details,
        covers: counts.covers,
      ),
    );
  }

  void _show(LoadProgress progress) {
    if (progress == _progress) return;
    _progress = progress;
    _loadProgress.add(progress);
  }

  /// Runs the trickles again for what their last run had to skip, when the
  /// window comes back. Each title waits on the gate as usual, so this never
  /// floods MAL while the connection is still down.
  Future<void> retryLeftBehind() async {
    if (_busy || _stopped) return;
    final details = trickle;
    final covers = coverTrickle;
    final redoDetails = details?.leftBehind ?? false;
    if (!redoDetails && !(covers?.leftBehind ?? false)) return;
    await _whileBusy(() async {
      await _loadAll(
        redoDetails: redoDetails,
        redoCovers: redoDetails || (covers?.leftBehind ?? false),
      );
      notifyDataChanged();
    });
  }

  var _busy = false;

  Future<void> _whileBusy(Future<void> Function() work) async {
    _busy = true;
    try {
      await work();
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    _stopped = true;
    trickle?.stop();
    coverTrickle?.stop();
    await sync?.runBeforeClose();
    sync?.dispose();
    log('app', 'closing');
    await closeLog();
  }
}
