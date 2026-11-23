import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../data/details_database.dart';
import '../data/record_database.dart';
import 'request_gate.dart';

const shortDetailFields =
    'id,title,main_picture,alternative_titles,start_date,end_date,nsfw,'
    'media_type,status,num_episodes,average_episode_duration,start_season,'
    'broadcast,related_anime{media_type,status,start_date,num_episodes}';

const fullDetailFields =
    '$shortDetailFields,synopsis,mean,rank,popularity,num_list_users,'
    'num_scoring_users,genres,created_at,updated_at,source,rating,pictures,'
    'background,related_manga,recommendations,studios,statistics,videos,'
    'opening_themes,ending_themes';

enum FetchOutcome {
  fetched,
  gone,
  offline,
  failed;

  bool get didFail => this == offline || this == failed;
}

const goneRecheck = Duration(days: 30);

/// The MAL pages found gone within the last [goneRecheck]; older ones are due
/// another look.
Future<Set<int>> readGonePages(RecordDatabase record, DateTime now) async {
  final rows = await record
      .customSelect(
        "SELECT provider_id FROM details.gone_page "
        "WHERE provider = 'mal' AND checked_at > ?",
        variables: [
          Variable.withInt(now.subtract(goneRecheck).millisecondsSinceEpoch),
        ],
      )
      .get();
  return {for (final row in rows) row.read<int>('provider_id')};
}

const changingStatuses = {'currently_airing', 'not_yet_aired'};

Future<http.Response> getDetail(
  http.Client client, {
  required String clientId,
  required int malId,
  required String fields,
}) => client.get(
  Uri.https('api.myanimelist.net', '/v2/anime/$malId', {'fields': fields}),
  headers: {'X-MAL-CLIENT-ID': clientId},
);

class DetailRequest {
  DetailRequest({
    required this.clientId,
    required this.client,
    required this.gate,
    required this.details,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String clientId;
  final http.Client client;
  final RequestGate gate;
  final DetailsDatabase details;
  final DateTime Function() _now;

  Future<FetchOutcome> fetch(
    int malId, {
    required Lane lane,
    required bool full,
    bool Function()? wanted,
  }) async {
    // a full row is never swapped for a short one
    final keepFull = full || await _holdsFull(malId);
    final http.Response response;
    try {
      response = await gate.send(
        lane,
        () => getDetail(
          client,
          clientId: clientId,
          malId: malId,
          fields: keepFull ? fullDetailFields : shortDetailFields,
        ),
        wanted: wanted,
      );
    } on RequestCancelled {
      return FetchOutcome.failed;
    } on Exception {
      return FetchOutcome.offline;
    }
    final checkedAt = _now().millisecondsSinceEpoch;
    if (response.statusCode == 404) {
      await details
          .into(details.gonePage)
          .insertOnConflictUpdate(
            GonePageCompanion.insert(
              provider: 'mal',
              providerId: malId,
              checkedAt: checkedAt,
            ),
          );
      return FetchOutcome.gone;
    }
    if (response.statusCode != 200) return FetchOutcome.failed;
    final json = _readTitle(response.bodyBytes, malId);
    // the title columns read this json, so a bad row would break every list read
    if (json == null) return FetchOutcome.failed;

    await details.transaction(() async {
      await details
          .into(details.detail)
          .insertOnConflictUpdate(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: malId,
              fetchedAt: checkedAt,
              json: json,
              isFull: Value(keepFull),
            ),
          );
      await (details.delete(details.gonePage)..where(
            (gone) =>
                gone.provider.equals('mal') & gone.providerId.equals(malId),
          ))
          .go();
    });
    return FetchOutcome.fetched;
  }

  String? _readTitle(List<int> bytes, int malId) {
    try {
      // the body is utf-8; http assumes latin-1 when no charset is sent
      final text = utf8.decode(bytes);
      final body = jsonDecode(text);
      return body is Map && body['id'] == malId ? text : null;
    } on FormatException {
      return null;
    }
  }

  Future<bool> _holdsFull(int malId) async {
    final saved =
        await (details.select(details.detail)..where(
              (row) =>
                  row.provider.equals('mal') & row.providerId.equals(malId),
            ))
            .getSingleOrNull();
    return saved?.isFull ?? false;
  }
}
