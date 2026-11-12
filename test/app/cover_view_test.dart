import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/app/cover_view.dart';
import 'package:konsou/components/skeleton.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/covers/cover_size.dart';
import 'package:konsou/covers/cover_store.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/mal/request_gate.dart';

void main() {
  group('the cover provider', () {
    late Directory folder;
    late Databases databases;
    late List<String> asked;
    late CoverStore store;

    setUp(() async {
      folder = Directory.systemTemp.createTempSync('konsou_cover_view');
      databases = await openDatabases(folder);
      asked = [];
      store = CoverStore(
        databases: databases,
        folder: Directory('${folder.path}/covers'),
        client: MockClient((request) async {
          asked.add(request.url.toString());
          return http.Response.bytes(
            [1, 2, 3],
            200,
            headers: {'content-type': 'image/webp'},
          );
        }),
        gate: RequestGate(wait: (_) async {}),
      );
      final details = databases.details;
      await details
          .into(details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: 1,
              fetchedAt: 1,
              json:
                  '{"main_picture": {"medium": '
                  '"https://cdn.myanimelist.net/images/anime/1/1.webp", '
                  '"large": "https://cdn.myanimelist.net/images/anime/1/1l.webp"}}',
            ),
          );
    });

    tearDown(() async {
      await databases.close();
      folder.deleteSync(recursive: true);
    });

    ProviderContainer containerWith(CoverStore? coverStore) {
      final container = ProviderContainer(
        overrides: [coverStoreProvider.overrideWithValue(coverStore)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('a cover is fetched once, then read from the device', () async {
      final container = containerWith(store);
      // a card on screen listens; a provider nobody listens to is dropped,
      // and with it any fetch still waiting in the queue
      container.listen(
        coverFileProvider(1, CoverSize.medium),
        (previous, next) {},
      );
      final first = await container.read(
        coverFileProvider(1, CoverSize.medium).future,
      );
      expect(first, isNotNull);
      expect(asked, hasLength(1));
      container.invalidate(coverFileProvider(1, CoverSize.medium));
      await container.read(coverFileProvider(1, CoverSize.medium).future);
      expect(asked, hasLength(1));
    });

    test('a title with no details has no cover and asks nothing', () async {
      final container = containerWith(store);
      expect(
        await container.read(coverFileProvider(2, CoverSize.medium).future),
        isNull,
      );
      expect(asked, isEmpty);
    });

    test('without a store there is no cover', () async {
      final container = containerWith(null);
      expect(
        await container.read(coverFileProvider(1, CoverSize.medium).future),
        isNull,
      );
    });
  });

  group('the view', () {
    Widget app(ProviderContainer container, int? malId) =>
        UncontrolledProviderScope(
          container: container,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: CoverView(malId: malId, width: 40),
            ),
          ),
        );

    testWidgets('shows the cover once it has come in', (tester) async {
      final folder = Directory.systemTemp.createTempSync('konsou_cover_view');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/1.webp')..writeAsBytesSync([1, 2, 3]);
      final container = ProviderContainer(
        overrides: [
          coverStoreProvider.overrideWithValue(null),
          coverFileProvider(
            1,
            CoverSize.medium,
          ).overrideWith((ref) async => file),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container, 1));
      expect(find.byType(Image), findsNothing);
      await tester.pump();
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a kept cover is drawn with no fetch and no skeleton', (
      tester,
    ) async {
      final folder = Directory.systemTemp.createTempSync('konsou_cover_view');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/1.webp')..writeAsBytesSync([1, 2, 3]);
      var fetched = 0;
      final container = ProviderContainer(
        overrides: [
          keptCoversProvider.overrideWith(() => _Kept(file)),
          coverFileProvider(1, CoverSize.medium).overrideWith((ref) async {
            fetched++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container, 1));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);
      expect(fetched, 0);
    });

    testWidgets('an entry not linked yet shows the blank cover', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container, null));
      expect(find.byType(Image), findsNothing);
    });
  });
}

class _Kept extends KeptCovers {
  _Kept(this.file);

  final File file;

  @override
  Future<Map<(int, CoverSize), File>> build() async => {
    (1, CoverSize.medium): file,
  };
}
