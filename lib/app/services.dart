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
import '../sync/drive_client.dart';
import '../sync/drive_sync.dart';
import '../sync/google_sign_in.dart';
import 'keys.dart';

/// The background work, built once at launch: sync, then the trickle (details,
/// then matching), then the covers, then the franchise scan.
class Services {
  Services({
    required this.databases,
    required this.keys,
    required this.coversFolder,
    required http.Client client,
    required TokenStore tokenStore,
    required Future<void> Function(Uri url) openBrowser,
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
      final requestGate = gate ?? RequestGate();
      final detailRequest = DetailRequest(
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
      );
      coverTrickle = CoverTrickle(
        databases: databases,
        store: CoverStore(
          databases: databases,
          folder: coversFolder,
          client: client,
          // the image server is not the API: its own gate
          gate: RequestGate(),
        ),
      );
      scan = FranchiseScan(databases: databases, detailRequest: detailRequest);
    }
  }

  final Databases databases;
  final Keys keys;
  final Directory coversFolder;
  GoogleSignIn? signIn;
  DriveSync? sync;
  Matching? matching;
  Trickle? trickle;
  CoverTrickle? coverTrickle;
  FranchiseScan? scan;
  var _stopped = false;

  /// Runs the chain once and returns when it ends or [stop] is called.
  Future<void> start() async {
    await sync?.run();
    if (_stopped) return;
    await trickle?.run();
    if (_stopped) return;
    await coverTrickle?.run();
    if (_stopped) return;
    await scan?.run();
  }

  /// Ends the chain and gives sync its close run, which has its own limit.
  Future<void> stop() async {
    _stopped = true;
    trickle?.stop();
    coverTrickle?.stop();
    await sync?.runBeforeClose();
    sync?.dispose();
  }
}
