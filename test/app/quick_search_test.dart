import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/app/keys.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/quick_search_providers.dart';
import 'package:konsou/app/services.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/library/quick_search.dart';

import '../support/fake_google.dart';

Map<String, dynamic> _page(
  int id,
  String title, {
  String status = 'finished_airing',
}) => {
  'node': {
    'id': id,
    'title': title,
    'media_type': 'tv',
    'status': status,
    'num_episodes': 12,
    'start_date': '2023-09-29',
    'alternative_titles': <String, dynamic>{},
  },
};

void main() {
  late Directory folder;
  late Databases databases;
  late ProviderContainer container;
  var requests = <Uri>[];

  QuickSearch search() => container.read(quickSearchProvider.notifier);
  QuickState state() => container.read(quickSearchProvider);

  Future<void> addEntry(
    String id,
    String name, {
    String status = 'watching',
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
            progressChangedAt: 1,
            name: Value(name),
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

  /// MAL answering every search with [all], a page at a time.
  Future<void> start(List<Map<String, dynamic>> all) async {
    folder = Directory.systemTemp.createTempSync('konsou_quick_search_test');
    databases = await openDatabases(folder);
    requests = [];
    final client = MockClient((request) async {
      requests.add(request.url);
      final offset = int.parse(request.url.queryParameters['offset'] ?? '0');
      final limit = int.parse(request.url.queryParameters['limit']!);
      return http.Response(
        jsonEncode({'data': all.skip(offset).take(limit).toList()}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final services = Services(
      databases: databases,
      keys: const Keys(
        malClientId: 'mal',
        googleClientId: '',
        googleClientSecret: '',
      ),
      coversFolder: Directory('${folder.path}/covers'),
      client: client,
      tokenStore: MemoryTokenStore(),
      openBrowser: (_) async {},
      gate: RequestGate(gap: Duration.zero),
    );
    container = ProviderContainer(
      overrides: [servicesProvider.overrideWithValue(services)],
    );
  }

  // the pause before the online search, and the search itself
  Future<void> settle() => Future<void>.delayed(
    quickSearchDebounce + const Duration(milliseconds: 400),
  );

  tearDown(() async {
    container.dispose();
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  test('opens on the recent entries', () async {
    await start([]);
    for (var i = 0; i < 7; i++) {
      await addEntry('e$i', 'Title $i');
    }
    await search().open();
    expect(state().open, isTrue);
    expect(state().recent, hasLength(5));
    expect(state().rows, hasLength(5));
  });

  test('your list shows first, and online results never repeat it', () async {
    await start([_page(1, 'Frieren'), _page(2, 'Frieren Recap')]);
    await addEntry('a', 'Frieren', malId: 1);
    await search().open();
    search().setQuery('frieren');
    // the list answers at once, before the online search has run
    expect(state().mine.map((row) => row.name), ['Frieren']);
    expect(state().searching, isTrue);
    await settle();
    expect(state().searching, isFalse);
    expect(state().online.map((row) => row.name), ['Frieren Recap']);
    expect(state().rows.map((row) => row.name), ['Frieren', 'Frieren Recap']);
  });

  test('the online results show even when the list matches', () async {
    await start([_page(5, 'Oshi no Ko Season 2')]);
    await addEntry('a', 'Oshi no Ko');
    await search().open();
    search().setQuery('oshi no');
    await settle();
    expect(state().mine, hasLength(1));
    expect(state().online, hasLength(1));
  });

  test('a short search stays on the list and never asks online', () async {
    await start([_page(1, 'Ab')]);
    await addEntry('a', 'Abc');
    await search().open();
    search().setQuery('ab');
    await settle();
    expect(requests, isEmpty);
    expect(state().searching, isFalse);
  });

  test(
    'Load more shows the next rows and asks online for the next page',
    () async {
      await start([for (var i = 1; i <= 25; i++) _page(i, 'Frieren $i')]);
      await search().open();
      search().setQuery('frieren');
      await settle();
      expect(state().online, hasLength(quickPage));
      expect(state().shownOnline, hasLength(quickFirst));
      expect(state().hasMore, isTrue);

      // ten more rows show, so the second page is asked for at once, and the
      // highlight lands on the first new row
      await search().loadMore();
      expect(requests.last.queryParameters['offset'], '10');
      expect(state().online, hasLength(20));
      expect(state().shownOnline, hasLength(quickFirst + quickPage));
      expect(state().focus, quickFirst);

      // the last page has five, so nothing more is asked for, but one row is
      // still hidden
      await search().loadMore();
      expect(requests.last.queryParameters['offset'], '20');
      expect(state().online, hasLength(25));
      expect(state().onlineMore, isFalse);
      expect(state().shownOnline, hasLength(24));
      expect(state().hasMore, isTrue);

      await search().loadMore();
      expect(state().shownOnline, hasLength(25));
      expect(state().hasMore, isFalse);
    },
  );

  test('Load more asked twice at once fetches one page', () async {
    await start([for (var i = 1; i <= 25; i++) _page(i, 'Frieren $i')]);
    await search().open();
    search().setQuery('frieren');
    await settle();
    await Future.wait([search().loadMore(), search().loadMore()]);
    expect(state().online, hasLength(20));
    expect(state().shownOnline, hasLength(quickFirst + quickPage));
  });

  test('the arrow keys move through the rows and Load more', () async {
    await start([for (var i = 1; i <= 25; i++) _page(i, 'Frieren $i')]);
    await search().open();
    search().setQuery('frieren');
    await settle();
    final last = state().rows.length;
    search().moveFocus(100);
    expect(state().focus, last); // the Load more row
    search().moveFocus(-100);
    expect(state().focus, 0);
  });

  test('ticking a title not on the list adds it as Completed', () async {
    await start([_page(7, 'Frieren Recap')]);
    await search().open();
    search().setQuery('frieren');
    await settle();
    await search().toggleComplete(state().online.single);
    final record = databases.record;
    final entries = await record.select(record.entry).get();
    expect(
      (entries.single.status, entries.single.episodesWatched),
      ('completed', 12),
    );
    // it moved from the online group to the list
    expect(state().online, isEmpty);
    expect(state().mine.single.completed, isTrue);
  });

  test('a title still airing is not added as Completed', () async {
    await start([_page(8, 'Frieren Next', status: 'currently_airing')]);
    await search().open();
    search().setQuery('frieren');
    await settle();
    await search().toggleComplete(state().online.single);
    final record = databases.record;
    expect(await record.select(record.entry).get(), isEmpty);
    expect(state().online, hasLength(1));
  });

  test('closing clears the search', () async {
    await start([]);
    await search().open();
    search().setQuery('frieren');
    search().close();
    expect(state().open, isFalse);
    expect(state().query, isEmpty);
  });
}
