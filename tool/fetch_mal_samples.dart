// Fetches the MAL responses the tests read and saves them trimmed, so no MAL
// prose lands in this public repo. Run from the repo root with MAL_CLIENT_ID
// in .env:
//   dart run tool/fetch_mal_samples.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/request_gate.dart';

const _samples = {
  'frieren_full': (52991, fullDetailFields),
  'frieren_short': (52991, shortDetailFields),
  'one_piece_short': (21, shortDetailFields),
};

const _placeholder = 'Replaced so the repo carries no MAL text.';

Future<void> main() async {
  final clientId = _readClientId();
  final gate = RequestGate();
  final client = http.Client();
  try {
    for (final MapEntry(key: name, value: (id, fields)) in _samples.entries) {
      final response = await gate.send(
        Lane.screen,
        () => client.get(
          Uri.https('api.myanimelist.net', '/v2/anime/$id', {'fields': fields}),
          headers: {'X-MAL-CLIENT-ID': clientId},
        ),
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

String _readClientId() {
  for (final line in File('.env').readAsLinesSync()) {
    if (line.startsWith('MAL_CLIENT_ID=')) {
      final id = line.substring('MAL_CLIENT_ID='.length).trim();
      if (id.isNotEmpty) return id;
    }
  }
  stderr.writeln('MAL_CLIENT_ID is missing from .env');
  exit(2);
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
