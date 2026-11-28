import 'dart:convert';

import 'package:http/http.dart' as http;

/// One GET to MAL's API at `/v2/[path]` with [query], signed with the client
/// ID. Callers send it through the request gate.
Future<http.Response> getMal(
  http.Client client, {
  required String clientId,
  required String path,
  required Map<String, String> query,
}) => client.get(
  Uri.https('api.myanimelist.net', '/v2/$path', query),
  headers: {'X-MAL-CLIENT-ID': clientId},
);

/// MAL's answer as text and as JSON, or null when it is not JSON.
({String text, Object? json})? readMalBody(List<int> bytes) {
  try {
    // the body is utf-8; http assumes latin-1 when no charset is sent
    final text = utf8.decode(bytes);
    return (text: text, json: jsonDecode(text));
  } on FormatException {
    return null;
  }
}
