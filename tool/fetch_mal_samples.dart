import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/request_gate.dart';

import 'mal_client_id.dart';

const _samples = {
  'frieren_full': (52991, fullDetailFields),
  'frieren_short': (52991, shortDetailFields),
  'one_piece_short': (21, shortDetailFields),
};

const _placeholder = 'Replaced so the repo carries no MAL text.';

/// Fetches the MAL responses the tests read and saves them trimmed, so no MAL
/// prose lands in this public repo. Run from the repo root with MAL_CLIENT_ID
/// in .env:
///   dart run tool/fetch_mal_samples.dart
Future<void> main() async {
  final clientId = readMalClientId();
  final gate = RequestGate();
  final client = http.Client();
  try {
    for (final MapEntry(key: name, value: (id, fields)) in _samples.entries) {
      final response = await gate.send(
        Lane.screen,
        () => getDetail(client, clientId: clientId, malId: id, fields: fields),
      );
      if (response.statusCode != 200) {
        stderr.writeln('$name: HTTP ${response.statusCode}');
        exitCode = 1;
        continue;
      }
      final trimmed = _trim(jsonDecode(response.body) as Map<String, dynamic>);
      File('test/mal/samples/$name.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(trimmed)}\n',
      );
      stdout.writeln('$name: saved');
    }
  } finally {
    client.close();
  }
}

Map<String, dynamic> _trim(Map<String, dynamic> response) {
  for (final key in ['synopsis', 'background']) {
    if (response.containsKey(key)) response[key] = _placeholder;
  }
  for (final key in ['opening_themes', 'ending_themes']) {
    final themes = response[key];
    if (themes is List) {
      for (final theme in themes.cast<Map<String, dynamic>>()) {
        theme['text'] = _placeholder;
      }
    }
  }
  return response;
}
