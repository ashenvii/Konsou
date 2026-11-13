import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/app/keys.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/services.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/detail/streamer_mode.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/request_gate.dart';

import '../support/detail_rows.dart';
import '../support/fake_google.dart';

const _frieren = 52991;

void main() {
  late Directory folder;
  late Databases databases;
  late ProviderContainer container;
  late List<String?> asked;
  late http.Response Function() answer;
  Completer<void>? hold;
  final shortJson = File('test/mal/samples/frieren_short.json')
      .readAsStringSync();
  final fullJson = File('test/mal/samples/frieren_full.json')
      .readAsStringSync();

  http.Response found() => http.Response.bytes(utf8.encode(fullJson), 200);

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_detail_providers');
    databases = await openDatabases(folder);
    asked = [];
    answer = found;
    hold = null;
    final services = Services(
      databases: databases,
      keys: const Keys(
        malClientId: 'test-client',
        googleClientId: '',
        googleClientSecret: '',
      ),
      coversFolder: Directory('${folder.path}/covers'),
      client: MockClient((request) async {
        asked.add(request.url.queryParameters['fields']);
        await hold?.future;
        return answer();
      }),
      tokenStore: MemoryTokenStore(),
      openBrowser: (_) async {},
      gate: RequestGate(wait: (_) async {}),
    );
    container = ProviderContainer(
      overrides: [servicesProvider.overrideWithValue(services)],
    );
  });

  tearDown(() async {
    container.dispose();
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> save(String json, {required bool full, int? fetchedAt}) =>
      databases.details
          .into(databases.details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: _frieren,
              fetchedAt: fetchedAt ?? DateTime.now().millisecondsSinceEpoch,
              json: json,
              isFull: Value(full),
            ),
          );

  /// Keeps the provider alive and waits until its value passes [test].
  Future<T> waitFor<T>(
    ProviderListenable<AsyncValue<T>> provider,
    bool Function(T value) test,
  ) async {
    final watching = container.listen(provider, (_, _) {});
    addTearDown(watching.close);
    for (var tries = 0; tries < 200; tries++) {
      final shown = watching.read();
      final value = shown.value;
      if (!shown.isLoading && value != null && test(value)) return value;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('the provider never got there: ${watching.read()}');
  }

  final page = detailPageProvider(_frieren);
  bool settled(DetailPageData data) => data.fetch != DetailFetch.running;

  group('opening a title', () {
    test(
      'with nothing saved, fetches the full details in the screen lane',
      () async {
        hold = Completer();
        final first = await waitFor(page, (_) => true);
        expect((first.details, first.fetch), (null, DetailFetch.running));

        hold!.complete();
        final data = await waitFor(page, settled);
        expect(data.fetch, DetailFetch.idle);
        expect(data.details!.name, 'Sousou no Frieren');
        expect(data.details!.isFull, isTrue);
        expect(asked, [fullDetailFields]);
      },
    );

    test('a short row shows at once, then the full one replaces it', () async {
      await save(shortJson, full: false);
      hold = Completer();
      final first = await waitFor(page, (_) => true);
      expect(first.details!.isFull, isFalse);
      expect(first.fetch, DetailFetch.running);

      hold!.complete();
      final data = await waitFor(page, settled);
      expect(data.details!.score, 9.24);
    });

    test('a fresh full row is not fetched again', () async {
      await save(fullJson, full: true);
      final data = await waitFor(page, settled);

      expect(data.fetch, DetailFetch.idle);
      expect(asked, isEmpty);
    });

    test('a stale full row is fetched again', () async {
      await save(fullJson, full: true, fetchedAt: 1);
      await waitFor(page, settled);

      expect(asked, hasLength(1));
    });

    test('offline keeps the saved details, and Retry fetches', () async {
      await save(shortJson, full: false);
      answer = () => throw const SocketException('no network');
      final offline = await waitFor(page, settled);
      expect(offline.fetch, DetailFetch.offline);
      expect(offline.details!.name, 'Sousou no Frieren');

      answer = found;
      await container.read(page.notifier).retry();
      final data = await waitFor(page, settled);
      expect((data.fetch, data.details!.isFull), (DetailFetch.idle, true));
    });

    test('a server error with nothing saved says failed', () async {
      answer = () => http.Response('', 500);
      final data = await waitFor(page, settled);

      expect((data.details, data.fetch), (null, DetailFetch.failed));
    });

    test('a page the provider no longer has says gone', () async {
      answer = () => http.Response('', 404);

      expect((await waitFor(page, settled)).fetch, DetailFetch.gone);
    });
  });

  group('the entry', () {
    test('a title not on the list has none', () async {
      await save(fullJson, full: true);

      expect((await waitFor(page, settled)).entry, isNull);
    });

    test('is carried, and follows an edit without another fetch', () async {
      await save(fullJson, full: true);
      await addEntry(databases, 'a', malId: _frieren, status: 'watching');
      final before = await waitFor(page, settled);
      expect(before.entry!.score, isNull);

      await container.read(entryEditsProvider).setScore('a', 9);
      final after = await waitFor(page, (data) => data.entry?.score == 9);
      expect(after.details!.name, 'Sousou no Frieren');
      expect(asked, isEmpty);
    });

    test('the entry the user opened is the one shown', () async {
      await save(fullJson, full: true);
      await addEntry(databases, 'old', malId: _frieren, changedAt: 5);
      await addEntry(databases, 'new', malId: _frieren, changedAt: 9);
      final opened = detailPageProvider(_frieren, entryId: 'old');

      expect((await waitFor(opened, settled)).entry!.entryId, 'old');
      expect((await waitFor(page, settled)).entry!.entryId, 'new');
    });

    test('removing it leaves the page open, not on the list', () async {
      await save(fullJson, full: true);
      await addEntry(databases, 'a', malId: _frieren);
      await waitFor(page, (data) => data.entry != null);

      await container.read(entryEditsProvider).remove(['a']);
      final after = await waitFor(page, (data) => data.entry == null);
      expect(after.details, isNotNull);
    });
  });

  test('an adult title is hidden while Streamer mode is on', () async {
    final adult = (jsonDecode(fullJson) as Map<String, dynamic>)
      ..['nsfw'] = 'black';
    await save(jsonEncode(adult), full: true);
    expect((await waitFor(page, settled)).isHidden, isFalse);

    final record = databases.record;
    await record
        .into(record.setting)
        .insert(SettingCompanion.insert(key: streamerModeKey, value: 'true'));
    container.invalidate(page);
    expect((await waitFor(page, settled)).isHidden, isTrue);
  });

  test('the watch order follows an edit', () async {
    await addTitle(
      databases,
      1,
      '2019-01-01',
      relations: [relate(2, 'sequel')],
    );
    await addTitle(
      databases,
      2,
      '2020-01-01',
      relations: [relate(1, 'prequel')],
    );
    await addEntry(databases, 'a', malId: 1, status: 'watching');
    final order = watchOrderProvider(1);
    expect((await waitFor(order, (_) => true)).rows, hasLength(2));

    await container.read(entryEditsProvider).setEpisodes('a', 4);
    final after = await waitFor(
      order,
      (value) => value.rows.first.episodesWatched == 4,
    );
    expect(after.onList, 1);
  });

  group('a not-linked entry', () {
    Future<void> suggest(int malId, int position) => databases.details
        .into(databases.details.matchSuggestion)
        .insert(
          MatchSuggestionCompanion.insert(
            entryId: 'a',
            provider: 'mal',
            providerId: malId,
            position: position,
            json: '{"id": $malId, "title": "Page $malId"}',
            foundAt: 1,
          ),
        );

    test('shows its saved name and what Konsou found for it', () async {
      await addEntry(databases, 'a', name: 'Rick and Morty: The Anime');
      await suggest(7, 0);
      final picker = await waitFor(notLinkedPageProvider('a'), (_) => true);

      expect(picker.entry!.name, 'Rick and Morty: The Anime');
      expect(picker.entry!.isNotLinked, isTrue);
      expect([for (final found in picker.suggestions) found.name], ['Page 7']);
    });

    test('a pick links it, and "None of these" empties the list', () async {
      await addEntry(databases, 'a', name: 'Rick and Morty: The Anime');
      await suggest(7, 0);
      await suggest(8, 1);
      final picker = notLinkedPageProvider('a');
      await waitFor(picker, (value) => value.suggestions.length == 2);
      final matching = container.read(servicesProvider).matching!;

      await matching.declineSuggestions('a');
      await waitFor(picker, (value) => value.suggestions.isEmpty);

      await matching.linkEntry('a', _frieren, lane: Lane.screen, full: true);
      final linked = await waitFor(
        picker,
        (value) => value.entry?.malId != null,
      );
      expect(linked.entry!.malId, _frieren);
      expect(asked, [fullDetailFields]);
    });
  });
}
