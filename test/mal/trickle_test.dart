import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/matching.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/mal/search_request.dart';
import 'package:konsou/mal/trickle.dart';

final _now = DateTime.utc(2026, 11, 8, 12);

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_trickle_test');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addEntry(
    String id,
    String status,
    int updatedAt, {
    int? malId,
  }) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: id,
            status: status,
            addedAt: 1,
            progressChangedAt: updatedAt,
          ),
        );
    if (malId == null) return;
    await record
        .into(record.entryReference)
        .insert(
          EntryReferenceCompanion.insert(
            entryId: id,
            provider: 'mal',
            providerId: malId,
          ),
        );
  }

  Future<void> markGone(int malId, Duration ago) {
    final details = databases.details;
    return details
        .into(details.gonePage)
        .insert(
          GonePageCompanion.insert(
            provider: 'mal',
            providerId: malId,
            checkedAt: _now.subtract(ago).millisecondsSinceEpoch,
          ),
        );
  }

  /// A trickle whose requests answer through [respond], noting each title asked.
  /// Searches answer with no results, so matching asks nothing for a detail.
  Trickle trickleAnswering(
    List<int> asked,
    http.Response Function(int malId) respond,
  ) {
    final client = MockClient((request) async {
      if (request.url.pathSegments.last == 'anime') {
        return http.Response('{"data": []}', 200);
      }
      final malId = int.parse(request.url.pathSegments.last);
      asked.add(malId);
      return respond(malId);
    });
    final gate = RequestGate(wait: (_) async {});
    final detailRequest = DetailRequest(
      clientId: 'test-client',
      client: client,
      gate: gate,
      details: databases.details,
      now: () => _now,
    );
    return Trickle(
      record: databases.record,
      detailRequest: detailRequest,
      matching: Matching(
        databases: databases,
        searchRequest: SearchRequest(
          clientId: 'test-client',
          client: client,
          gate: gate,
        ),
        detailRequest: detailRequest,
        now: () => _now,
      ),
      now: () => _now,
    );
  }

  test('fetches in the agreed order and skips what it should', () async {
    await addEntry('watching', 'watching', 100, malId: 1);
    await addEntry('completed', 'completed', 300, malId: 2);
    await addEntry('planned', 'plan_to_watch', 200, malId: 3);
    await addEntry('rewatching', 'rewatching', 400, malId: 4);
    await addEntry('has details', 'completed', 500, malId: 5);
    await addEntry('gone lately', 'dropped', 600, malId: 6);
    await addEntry('gone long ago', 'not_interested', 700, malId: 7);
    await addEntry('on hold', 'on_hold', 50, malId: 8);
    await addEntry('no mal page', 'watching', 900);
    await addEntry('refused', 'plan_to_watch', 150, malId: 9);
    final details = databases.details;
    await details
        .into(details.detail)
        .insert(
          DetailCompanion.insert(
            provider: 'mal',
            providerId: 5,
            fetchedAt: 1,
            json: '{"id": 5}',
          ),
        );
    await markGone(6, const Duration(days: 10));
    await markGone(7, const Duration(days: 31));

    final asked = <int>[];
    await trickleAnswering(
      asked,
      (malId) => malId == 9
          ? http.Response('', 403)
          : http.Response('{"id": $malId}', 200),
    ).run();

    // watching and rewatching share the first tier, most recently changed first
    expect(asked, [4, 1, 3, 9, 8, 2, 7]);
    final saved = await details.select(details.detail).get();
    expect(saved.map((row) => row.providerId).toSet(), {1, 2, 3, 4, 5, 7, 8});
    expect(
      saved.where((row) => row.providerId != 5).every((row) => !row.isFull),
      isTrue,
    );
  });

  test('stops when asked', () async {
    for (var i = 1; i <= 3; i++) {
      await addEntry('entry $i', 'watching', i, malId: i);
    }
    final asked = <int>[];
    late final Trickle trickle;
    trickle = trickleAnswering(asked, (_) {
      trickle.stop();
      return http.Response('{}', 200);
    });

    await trickle.run();

    expect(asked, hasLength(1));
  });

  test('matches not-linked entries once details are filled', () async {
    await addEntry('linked', 'watching', 1, malId: 1);
    await addEntry('not linked', 'watching', 2);
    final asked = <int>[];

    await trickleAnswering(
      asked,
      (malId) => http.Response('{"id": $malId}', 200),
    ).run();

    expect(asked, [1]);
    final details = databases.details;
    final attempts = await details.select(details.matchAttempt).get();
    expect(attempts.single.entryId, 'not linked');
  });
}
