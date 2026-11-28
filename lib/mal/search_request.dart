import 'package:http/http.dart' as http;

import 'mal_api.dart';
import 'request_gate.dart';

/// Enough to show a result and to judge it as a match.
const searchFields =
    'id,title,main_picture,alternative_titles,media_type,status,num_episodes,'
    'start_date,mean';

/// MAL refuses a query outside these lengths with a 400.
const minQueryLength = 3;

/// Longest search sent to MAL, in characters.
const maxQueryLength = 64;

/// The one place a MAL search request is built. Callers send it through the
/// request gate.
Future<http.Response> getSearch(
  http.Client client, {
  required String clientId,
  required String query,
  int limit = 10,
  int offset = 0,
}) => getMal(
  client,
  clientId: clientId,
  path: 'anime',
  query: {
    'q': query,
    'limit': '$limit',
    if (offset > 0) 'offset': '$offset',
    'fields': searchFields,
  },
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
    int limit = 10,
    int offset = 0,
  }) async {
    final runes = query.trim().runes;
    if (runes.length < minQueryLength) return [];
    final sent = String.fromCharCodes(runes.take(maxQueryLength)).trim();
    final http.Response response;
    try {
      response = await gate.send(
        lane,
        () => getSearch(
          client,
          clientId: clientId,
          query: sent,
          limit: limit,
          offset: offset,
        ),
      );
    } on Exception {
      return null;
    }
    if (response.statusCode != 200) return null;
    if (readMalBody(response.bodyBytes)?.json case {'data': final List found}) {
      return [
        for (final result in found)
          if (result is Map && result['node'] is Map<String, dynamic>)
            result['node'] as Map<String, dynamic>,
      ];
    }
    return null;
  }
}
