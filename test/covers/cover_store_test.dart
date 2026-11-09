import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/covers/cover_size.dart';
import 'package:konsou/covers/cover_store.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/mal/request_gate.dart';

const _mediumUrl = 'https://cdn.myanimelist.net/images/anime/1/10.webp';
const _largeUrl = 'https://cdn.myanimelist.net/images/anime/1/10l.webp';

String _json({String medium = _mediumUrl, String large = _largeUrl}) =>
    '{"title": "T", "main_picture": {"medium": "$medium", "large": "$large"}}';

void main() {
  late Directory folder;
  late Databases databases;
  late List<String> asked;
  late int answer;
  var now = DateTime.utc(2026, 11, 9, 12);

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_covers_test');
    databases = await openDatabases(folder);
    asked = [];
    answer = 200;
    now = DateTime.utc(2026, 11, 9, 12);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  CoverStore buildStore({int poolLimit = 1000, bool throws = false}) {
    final client = MockClient((request) async {
      asked.add(request.url.toString());
      if (throws) throw http.ClientException('offline');
      final bytes = List.filled(100, request.url.path.length);
      return http.Response.bytes(
        bytes,
        answer,
        headers: {'content-type': 'image/webp'},
      );
    });
    return CoverStore(
      databases: databases,
      folder: Directory('${folder.path}/covers'),
      client: client,
      gate: RequestGate(wait: (_) async {}),
      poolLimit: poolLimit,
      now: () => now,
    );
  }

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

  Future<void> addEntry(String id, int malId) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: id,
            status: 'watching',
            addedAt: 1,
            progressChangedAt: 1,
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
  }

  test('the pool holds 150 MB by default', () {
    expect(defaultPoolLimit, 150 * 1024 * 1024);
  });

  group('size', () {
    test('medium while the drawn picture fits its 225 pixels', () {
      expect(chooseCoverSize(drawnWidth: 100, pixelRatio: 2), CoverSize.medium);
      expect(chooseCoverSize(drawnWidth: 225, pixelRatio: 1), CoverSize.medium);
    });

    test('large once more pixels are needed', () {
      expect(chooseCoverSize(drawnWidth: 120, pixelRatio: 2), CoverSize.large);
      expect(chooseCoverSize(drawnWidth: 300, pixelRatio: 1), CoverSize.large);
    });
  });

  group('fetch', () {
    test('saves the file by MAL id and size, and a row for it', () async {
      await saveDetail(10, _json());
      final store = buildStore();
      final outcome = await store.fetchCover(
        10,
        CoverSize.medium,
        lane: Lane.screen,
      );
      expect(outcome, CoverOutcome.fetched);
      expect(asked, [_mediumUrl]);
      final file = await store.readCover(10, CoverSize.medium);
      expect(file, isNotNull);
      expect(
        file!.path.replaceAll(r'\', '/'),
        endsWith('covers/10-medium.webp'),
      );
      expect(file.lengthSync(), 100);
      final row = await databases.details
          .select(databases.details.cover)
          .getSingle();
      expect((row.url, row.bytes, row.size), (_mediumUrl, 100, 'medium'));
    });

    test('large comes from the large link', () async {
      await saveDetail(10, _json());
      final store = buildStore();
      await store.fetchCover(10, CoverSize.large, lane: Lane.screen);
      expect(asked, [_largeUrl]);
      expect(
        (await store.readCover(10, CoverSize.large))!.path,
        endsWith('10-large.webp'),
      );
    });

    test(
      'a cover already kept from the same link is not fetched again',
      () async {
        await saveDetail(10, _json());
        final store = buildStore();
        await store.fetchCover(10, CoverSize.medium, lane: Lane.screen);
        final outcome = await store.fetchCover(
          10,
          CoverSize.medium,
          lane: Lane.screen,
        );
        expect(outcome, CoverOutcome.current);
        expect(asked, hasLength(1));
      },
    );

    test('a changed link downloads again and removes the old file', () async {
      await saveDetail(10, _json());
      final store = buildStore();
      await store.fetchCover(10, CoverSize.medium, lane: Lane.screen);
      await saveDetail(
        10,
        _json(medium: 'https://cdn.myanimelist.net/images/anime/2/20.jpg'),
      );
      final outcome = await store.fetchCover(
        10,
        CoverSize.medium,
        lane: Lane.screen,
      );
      expect(outcome, CoverOutcome.fetched);
      final files = Directory('${folder.path}/covers').listSync();
      expect(files.map((file) => file.path.split(RegExp(r'[\\/]')).last), [
        '10-medium.jpg',
      ]);
    });

    test('a file deleted from disk is fetched again', () async {
      await saveDetail(10, _json());
      final store = buildStore();
      await store.fetchCover(10, CoverSize.medium, lane: Lane.screen);
      (await store.readCover(10, CoverSize.medium))!.deleteSync();
      final outcome = await store.fetchCover(
        10,
        CoverSize.medium,
        lane: Lane.screen,
      );
      expect(outcome, CoverOutcome.fetched);
      expect(asked, hasLength(2));
    });

    test('no details, or no picture in them, is none', () async {
      final store = buildStore();
      expect(
        await store.fetchCover(10, CoverSize.medium, lane: Lane.screen),
        CoverOutcome.none,
      );
      await saveDetail(10, '{"title": "T"}');
      expect(
        await store.fetchCover(10, CoverSize.medium, lane: Lane.screen),
        CoverOutcome.none,
      );
      expect(asked, isEmpty);
    });

    test('an error answer or no connection fails and keeps nothing', () async {
      await saveDetail(10, _json());
      answer = 500;
      expect(
        await buildStore().fetchCover(10, CoverSize.medium, lane: Lane.screen),
        CoverOutcome.failed,
      );
      expect(
        await buildStore(throws: true)
            .fetchCover(10, CoverSize.medium, lane: Lane.screen),
        CoverOutcome.failed,
      );
      expect(
        await databases.details.select(databases.details.cover).get(),
        isEmpty,
      );
    });

    test('an answer that is not an image fails', () async {
      await saveDetail(10, _json());
      final store = CoverStore(
        databases: databases,
        folder: Directory('${folder.path}/covers'),
        client: MockClient(
          (_) async => http.Response(
            '<html>',
            200,
            headers: {'content-type': 'text/html'},
          ),
        ),
        gate: RequestGate(wait: (_) async {}),
        now: () => now,
      );
      expect(
        await store.fetchCover(10, CoverSize.medium, lane: Lane.screen),
        CoverOutcome.failed,
      );
    });
  });

  group('read', () {
    test('nothing kept is null', () async {
      expect(await buildStore().readCover(10, CoverSize.medium), isNull);
    });

    test('a row whose file is gone is dropped', () async {
      await saveDetail(10, _json());
      final store = buildStore();
      await store.fetchCover(10, CoverSize.medium, lane: Lane.screen);
      (await store.readCover(10, CoverSize.medium))!.deleteSync();
      expect(await store.readCover(10, CoverSize.medium), isNull);
      expect(
        await databases.details.select(databases.details.cover).get(),
        isEmpty,
      );
    });

    test('showing a cover notes when', () async {
      await saveDetail(10, _json());
      final store = buildStore();
      await store.fetchCover(10, CoverSize.medium, lane: Lane.screen);
      now = now.add(const Duration(days: 1));
      await store.readCover(10, CoverSize.medium);
      final row = await databases.details
          .select(databases.details.cover)
          .getSingle();
      expect(row.shownAt, now.millisecondsSinceEpoch);
    });
  });

  group('pool', () {
    Future<void> keep(
      CoverStore store,
      int malId,
      CoverSize size,
      int day,
    ) async {
      await saveDetail(malId, _json());
      await store.fetchCover(malId, size, lane: Lane.screen);
      final details = databases.details;
      await (details.update(details.cover)..where(
            (row) => row.providerId.equals(malId) & row.size.equals(size.name),
          ))
          .write(
            CoverCompanion(
              shownAt: Value(
                DateTime.utc(2026, 11, day).millisecondsSinceEpoch,
              ),
            ),
          );
    }

    Future<List<String>> kept() async => [
      for (final row
          in await databases.details.select(databases.details.cover).get())
        '${row.providerId}-${row.size}',
    ]..sort();

    test('over the limit, the least recently shown go first', () async {
      final store = buildStore(poolLimit: 250);
      await keep(store, 1, CoverSize.large, 1);
      await keep(store, 2, CoverSize.large, 3);
      await keep(store, 3, CoverSize.large, 2);
      await store.trimPool();
      expect(await kept(), ['2-large', '3-large']);
      expect(Directory('${folder.path}/covers').listSync(), hasLength(2));
    });

    test('the medium cover of a library entry is never dropped', () async {
      final store = buildStore(poolLimit: 0);
      await addEntry('a', 1);
      await keep(store, 1, CoverSize.medium, 1);
      await keep(store, 2, CoverSize.medium, 2);
      await keep(store, 1, CoverSize.large, 3);
      await store.trimPool();
      expect(await kept(), ['1-medium']);
    });

    test('a removed entry is in the pool again', () async {
      final store = buildStore(poolLimit: 0);
      await addEntry('a', 1);
      await keep(store, 1, CoverSize.medium, 1);
      await store.trimPool();
      expect(await kept(), ['1-medium']);
      final record = databases.record;
      await record.delete(record.entry).go();
      await store.trimPool();
      expect(await kept(), isEmpty);
    });

    test('under the limit, nothing goes', () async {
      final store = buildStore(poolLimit: 1000);
      await keep(store, 1, CoverSize.large, 1);
      await keep(store, 2, CoverSize.medium, 2);
      await store.trimPool();
      expect(await kept(), ['1-large', '2-medium']);
    });
  });
}
