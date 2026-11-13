import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/request_gate.dart';

final _now = DateTime.utc(2026, 11, 8, 12);
const _day = Duration(days: 1);

void main() {
  late Directory folder;
  late Databases databases;
  final shortJson = File('test/mal/samples/frieren_short.json')
      .readAsStringSync();
  final fullJson = File('test/mal/samples/frieren_full.json')
      .readAsStringSync();

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_mal_test');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  DetailRequest detailRequest(MockClientHandler handler) => DetailRequest(
    clientId: 'test-client',
    client: MockClient(handler),
    gate: RequestGate(wait: (_) async {}),
    details: databases.details,
    now: () => _now,
  );

  Future<List<Map<String, Object?>>> rows(String table) async => [
    for (final row
        in await databases.details.customSelect('SELECT * FROM $table').get())
      row.data,
  ];

  test('a short fetch sends the client id and saves a short row', () async {
    late http.Request sent;
    final outcome = await detailRequest((request) async {
      sent = request;
      return http.Response.bytes(utf8.encode(shortJson), 200);
    }).fetch(52991, lane: Lane.trickle, full: false);

    expect(outcome, FetchOutcome.fetched);
    expect(sent.url.host, 'api.myanimelist.net');
    expect(sent.url.path, '/v2/anime/52991');
    expect(sent.url.queryParameters['fields'], shortDetailFields);
    expect(sent.headers['X-MAL-CLIENT-ID'], 'test-client');

    final details = databases.details;
    final row = await details.select(details.detail).getSingle();
    expect(row.providerId, 52991);
    expect(row.isFull, isFalse);
    expect(row.fetchedAt, _now.millisecondsSinceEpoch);
    expect(row.title, 'Sousou no Frieren');
    expect(row.titleJapanese, '葬送のフリーレン');
  });

  test('a full fetch asks for every field and saves a full row', () async {
    late http.Request sent;
    await detailRequest((request) async {
      sent = request;
      return http.Response.bytes(utf8.encode(fullJson), 200);
    }).fetch(52991, lane: Lane.screen, full: true);

    expect(sent.url.queryParameters['fields'], fullDetailFields);
    final details = databases.details;
    expect((await details.select(details.detail).getSingle()).isFull, isTrue);
  });

  test('a 404 marks the page as gone and saves no details', () async {
    final outcome = await detailRequest((_) async => http.Response('', 404))
        .fetch(52991, lane: Lane.trickle, full: false);

    expect(outcome, FetchOutcome.gone);
    expect(await rows('detail'), isEmpty);
    expect(await rows('gone_page'), [
      {
        'provider': 'mal',
        'provider_id': 52991,
        'checked_at': _now.millisecondsSinceEpoch,
      },
    ]);
  });

  test('a page that comes back clears its gone mark', () async {
    await detailRequest((_) async => http.Response('', 404))
        .fetch(52991, lane: Lane.trickle, full: false);
    await detailRequest(
      (_) async => http.Response.bytes(utf8.encode(shortJson), 200),
    ).fetch(52991, lane: Lane.trickle, full: false);

    expect(await rows('gone_page'), isEmpty);
    expect(await rows('detail'), hasLength(1));
  });

  test('a short fetch of a title held in full asks for all of it', () async {
    final asked = <String?>[];
    final request = detailRequest((sent) async {
      asked.add(sent.url.queryParameters['fields']);
      return http.Response.bytes(utf8.encode(fullJson), 200);
    });
    await request.fetch(52991, lane: Lane.screen, full: true);
    await request.fetch(52991, lane: Lane.trickle, full: false);

    expect(asked, [fullDetailFields, fullDetailFields]);
    final details = databases.details;
    expect((await details.select(details.detail).getSingle()).isFull, isTrue);
  });

  test('a server error or no network saves nothing', () async {
    final serverError = await detailRequest((_) async => http.Response('', 500))
        .fetch(52991, lane: Lane.trickle, full: false);
    final noNetwork = await detailRequest(
      (_) async => throw const SocketException('no network'),
    ).fetch(52991, lane: Lane.trickle, full: false);

    expect(serverError, FetchOutcome.failed);
    expect(noNetwork, FetchOutcome.offline);
    expect(await rows('detail'), isEmpty);
    expect(await rows('gone_page'), isEmpty);
  });

  group('a title on screen is stale', () {
    int fetchedAgo(Duration age) => _now.subtract(age).millisecondsSinceEpoch;

    test('after a day when airing or upcoming', () {
      for (final status in ['currently_airing', 'not_yet_aired']) {
        expect(
          isStale(
            airingStatus: status,
            fetchedAt: fetchedAgo(_day * 0.9),
            now: _now,
          ),
          isFalse,
        );
        expect(
          isStale(
            airingStatus: status,
            fetchedAt: fetchedAgo(_day * 1.1),
            now: _now,
          ),
          isTrue,
        );
      }
    });

    test('after 30 days when finished', () {
      expect(
        isStale(
          airingStatus: 'finished_airing',
          fetchedAt: fetchedAgo(_day * 29),
          now: _now,
        ),
        isFalse,
      );
      expect(
        isStale(
          airingStatus: 'finished_airing',
          fetchedAt: fetchedAgo(_day * 31),
          now: _now,
        ),
        isTrue,
      );
    });
  });
}
