import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/covers/cover_size.dart';
import 'package:konsou/covers/cover_store.dart';
import 'package:konsou/covers/cover_trickle.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/mal/request_gate.dart';

String _url(int malId, [String ext = 'webp']) =>
    'https://cdn.myanimelist.net/images/anime/1/$malId.$ext';

String _json(int malId, [String ext = 'webp']) =>
    '{"main_picture": {"medium": "${_url(malId, ext)}", '
    '"large": "${_url(malId, ext)}l"}}';

void main() {
  late Directory folder;
  late Databases databases;
  late List<String> asked;
  late Set<int> failing;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_cover_trickle');
    databases = await openDatabases(folder);
    asked = [];
    failing = {};
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  CoverStore buildStore({
    int poolLimit = defaultPoolLimit,
    void Function()? onRequest,
  }) => CoverStore(
    databases: databases,
    folder: Directory('${folder.path}/covers'),
    client: MockClient((request) async {
      asked.add(request.url.toString());
      onRequest?.call();
      final malId = int.parse(
        RegExp(r'/(\d+)').firstMatch(request.url.path)!.group(1)!,
      );
      if (failing.contains(malId)) return http.Response('', 500);
      return http.Response.bytes(
        [1, 2, 3],
        200,
        headers: {'content-type': 'image/webp'},
      );
    }),
    gate: RequestGate(wait: (_) async {}),
    poolLimit: poolLimit,
  );

  Future<void> saveDetail(int malId, String json) {
    final details = databases.details;
    return details
        .into(details.detail)
        .insertOnConflictUpdate(
          DetailCompanion.insert(
            provider: 'mal',
            providerId: malId,
            fetchedAt: 1,
            json: json,
          ),
        );
  }

  Future<void> addEntry(
    String id,
    int malId, {
    required int changedAt,
    bool withDetails = true,
  }) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: id,
            status: 'watching',
            addedAt: 1,
            progressChangedAt: changedAt,
          ),
        );
    await record
        .into(record.entryReference)
        .insert(
          EntryReferenceCompanion.insert(
            entryId: id,
            provider: 'mal',
            providerId: malId,
          ),
        );
    if (withDetails) await saveDetail(malId, _json(malId));
  }

  test('fetches the medium cover of each entry, newest change first', () async {
    await addEntry('old', 1, changedAt: 10);
    await addEntry('new', 2, changedAt: 20);
    await CoverTrickle(databases: databases, store: buildStore()).run();
    expect(asked, [_url(2), _url(1)]);
  });

  test('skips entries with no details and covers already kept', () async {
    await addEntry('a', 1, changedAt: 10);
    await addEntry('b', 2, changedAt: 20, withDetails: false);
    final store = buildStore();
    await store.fetchCover(1, CoverSize.medium, lane: Lane.screen);
    asked.clear();
    await CoverTrickle(databases: databases, store: store).run();
    expect(asked, isEmpty);
  });

  test('fetches again when the picture link changed', () async {
    await addEntry('a', 1, changedAt: 10);
    final store = buildStore();
    await CoverTrickle(databases: databases, store: store).run();
    await saveDetail(1, _json(1, 'jpg'));
    asked.clear();
    await CoverTrickle(databases: databases, store: store).run();
    expect(asked, [_url(1, 'jpg')]);
  });

  test('a cover whose file was deleted is fetched again', () async {
    await addEntry('a', 1, changedAt: 10);
    final store = buildStore();
    await CoverTrickle(databases: databases, store: store).run();
    (await store.readCover(1, CoverSize.medium))!.deleteSync();
    asked.clear();
    await CoverTrickle(databases: databases, store: store).run();
    expect(asked, [_url(1)]);
  });

  test('a failed cover does not hold up the rest or repeat', () async {
    await addEntry('a', 1, changedAt: 20);
    await addEntry('b', 2, changedAt: 10);
    failing = {1};
    await CoverTrickle(databases: databases, store: buildStore()).run();
    expect(asked, [_url(1), _url(2)]);
  });

  test('stop ends the run', () async {
    await addEntry('a', 1, changedAt: 20);
    await addEntry('b', 2, changedAt: 10);
    late CoverTrickle trickle;
    final store = buildStore(onRequest: () => trickle.stop());
    trickle = CoverTrickle(databases: databases, store: store);
    await trickle.run();
    expect(asked, hasLength(1));
  });

  test('trims the pool when it is done', () async {
    await addEntry('a', 1, changedAt: 10);
    await saveDetail(9, _json(9));
    final store = buildStore(poolLimit: 0);
    await store.fetchCover(9, CoverSize.medium, lane: Lane.screen);
    await CoverTrickle(databases: databases, store: store).run();
    final kept = await databases.details.select(databases.details.cover).get();
    expect(kept.map((row) => row.providerId), [1]);
  });
}
