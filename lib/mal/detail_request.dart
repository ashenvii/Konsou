import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../data/details_database.dart';
import 'request_gate.dart';

/// What the trickle asks for: enough for the Library, Watching and the
/// franchise walk.
const shortDetailFields =
    'id,title,main_picture,alternative_titles,start_date,end_date,nsfw,'
    'media_type,status,num_episodes,average_episode_duration,start_season,'
    'broadcast,related_anime{media_type,status,start_date,num_episodes}';

/// What a detail page asks for. videos and the theme songs are not in MAL's
/// documented list; they work today and may stop.
const fullDetailFields =
    '$shortDetailFields,synopsis,mean,rank,popularity,num_list_users,'
    'num_scoring_users,genres,created_at,updated_at,source,rating,pictures,'
    'background,related_manga,recommendations,studios,statistics,videos,'
    'opening_themes,ending_themes';

enum FetchOutcome { fetched, gone, failed }

/// How long a gone page is left alone before it is checked again.
const goneRecheck = Duration(days: 30);

/// MAL statuses whose details change weekly.
const changingStatuses = {'currently_airing', 'not_yet_aired'};

/// The one place a MAL detail request is built. Callers send it through the
/// request gate.
Future<http.Response> getDetail(
  http.Client client, {
  required String clientId,
  required int malId,
  required String fields,
}) => client.get(
  Uri.https('api.myanimelist.net', '/v2/anime/$malId', {'fields': fields}),
  headers: {'X-MAL-CLIENT-ID': clientId},
);

/// Fetches one title's details from MAL and saves what came back.
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
  }) async {
    final http.Response response;
    try {
      response = await gate.send(
        lane,
        () => getDetail(
          client,
          clientId: clientId,
          malId: malId,
          fields: full ? fullDetailFields : shortDetailFields,
        ),
      );
    } on Exception {
      return FetchOutcome.failed;
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

    await details.transaction(() async {
      await details
          .into(details.detail)
          .insertOnConflictUpdate(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: malId,
              fetchedAt: checkedAt,
              // the body is utf-8; http assumes latin-1 when no charset is sent
              json: utf8.decode(response.bodyBytes),
              isFull: Value(full),
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
}

/// Whether a title on screen should be fetched again. Airing and upcoming
/// titles change weekly; finished ones almost never.
bool isStale({
  required String? airingStatus,
  required int fetchedAt,
  required DateTime now,
}) {
  final maxAge = changingStatuses.contains(airingStatus)
      ? const Duration(days: 1)
      : const Duration(days: 30);
  return now.difference(DateTime.fromMillisecondsSinceEpoch(fetchedAt)) >
      maxAge;
}
