import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/mal/search_request.dart';
import 'package:konsou/search/title_words.dart';

void main() {
  final asked = <Uri>[];

  SearchRequest searchAnswering(http.Response Function() respond) {
    asked.clear();
    return SearchRequest(
      clientId: 'test-client',
      client: MockClient((request) async {
        asked.add(request.url);
        expect(request.headers['X-MAL-CLIENT-ID'], 'test-client');
        return respond();
      }),
      gate: RequestGate(wait: (_) async {}),
    );
  }

  http.Response readSample(String name) => http.Response.bytes(
    File('test/mal/samples/$name.json').readAsBytesSync(),
    200,
  );

  test('reads the titles MAL found, in its order', () async {
    final results = await searchAnswering(() => readSample('search_frieren'))
        .search('Sousou no Frieren', lane: Lane.screen);

    expect(results!.first['id'], 52991);
    expect(readProviderTitles(results.first), contains('Sousou no Frieren'));
    expect(asked.single.queryParameters['q'], 'Sousou no Frieren');
    expect(asked.single.queryParameters['fields'], searchFields);
  });

  test('nothing found is an empty list, a failure is null', () async {
    expect(
      await searchAnswering(() => readSample('search_nothing'))
          .search('Scott Pilgrim Takes Off', lane: Lane.trickle),
      isEmpty,
    );
    expect(
      await searchAnswering(() => http.Response('', 500))
          .search('Scott Pilgrim', lane: Lane.trickle),
      isNull,
    );
  });

  test('a short query asks nothing and a long one is cut', () async {
    final search = searchAnswering(() => readSample('search_nothing'));
    expect(await search.search(' ab ', lane: Lane.screen), isEmpty);
    expect(asked, isEmpty);

    await search.search('x' * 70, lane: Lane.screen);
    expect(asked.single.queryParameters['q'], 'x' * maxQueryLength);
  });
}
