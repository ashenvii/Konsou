import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:konsou/data/databases.dart';
import 'package:konsou/import/import_old_list.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/matching.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/mal/search_request.dart';

import 'mal_client_id.dart';

const _testList = 'testdata/konsou-test-list.db';
const _saved = 'testdata/match-searches.json';

/// Runs matching on the test list's not-linked entries against real MAL and
/// saves every search answer, so the test can replay them offline. The answers
/// name titles on the owner's list, so they go in testdata/, which git
/// ignores. Run from the repo root with MAL_CLIENT_ID in .env:
///   dart run tool/fetch_match_searches.dart
Future<void> main() async {
  final clientId = readMalClientId();
  final folder = Directory.systemTemp.createTempSync('konsou_match_searches');
  final databases = await openDatabases(folder);
  final client = _RecordingClient(http.Client());
  try {
    await importOldDatabase(File(_testList), databases);
    final gate = RequestGate();
    await Matching(
      databases: databases,
      searchRequest: SearchRequest(
        clientId: clientId,
        client: client,
        gate: gate,
      ),
      detailRequest: DetailRequest(
        clientId: clientId,
        client: client,
        gate: gate,
        details: databases.details,
      ),
    ).run();
    File(_saved).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(client.searches)}\n',
    );
    stdout.writeln('${client.searches.length} searches saved to $_saved');
  } finally {
    client.close();
    await databases.close();
    folder.deleteSync(recursive: true);
  }
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this._inner);

  final http.Client _inner;
  final searches = <String, Object?>{};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await http.Response.fromStream(await _inner.send(request));
    final query = request.url.queryParameters['q'];
    if (query != null && response.statusCode == 200) {
      searches[query] = jsonDecode(utf8.decode(response.bodyBytes));
    }
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }

  @override
  void close() => _inner.close();
}
