import 'dart:convert';

import 'package:http/http.dart' as http;

import 'request_gate.dart';

/// Enough to show a result and to judge it as a match.
const searchFields =
    'id,title,main_picture,alternative_titles,media_type,status,num_episodes,'
    'start_date';

/// MAL refuses a query outside these lengths with a 400.
const minQueryLength = 3;
const maxQueryLength = 64;

/// The one place a MAL search request is built. Callers send it through the
/// request gate.
Future<http.Response> getSearch(
  http.Client client, {
  required String clientId,
  required String query,
  int limit = 10,
}) => client.get(
  Uri.https('api.myanimelist.net', '/v2/anime', {
    'q': query,
    'limit': '$limit',
    'fields': searchFields,
  }),
  headers: {'X-MAL-CLIENT-ID': clientId},
);

/// Searches MAL by title.
class SearchRequest {
  SearchRequest({
    required this.clientId,
    required this.client,
    required this.gate,
  });

  final String clientId;
  final http.Client client;
  final RequestGate gate;

  /// The titles MAL found, best first, or null when the search failed. A query
  /// too short for MAL finds nothing without asking; a long one is cut.
  Future<List<Map<String, dynamic>>?> search(
    String query, {
    required Lane lane,
  }) async {
    final runes = query.trim().runes;
    if (runes.length < minQueryLength) return [];
    final sent = String.fromCharCodes(runes.take(maxQueryLength)).trim();
    final http.Response response;
    try {
      response = await gate.send(
        lane,
        () => getSearch(client, clientId: clientId, query: sent),
      );
    } on Exception {
      return null;
    }
    if (response.statusCode != 200) return null;
    // the body is utf-8; http assumes latin-1 when no charset is sent
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    return [
      for (final result in body['data'] as List)
        (result as Map)['node'] as Map<String, dynamic>,
    ];
  }
}
