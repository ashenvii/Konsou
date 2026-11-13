import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/app/keys.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/quick_search_layer.dart';
import 'package:konsou/app/quick_search_providers.dart';
import 'package:konsou/app/services.dart';
import 'package:konsou/components/sweep_button.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/mal/request_gate.dart';

import '../support/fake_google.dart';
import '../support/render_png.dart' show loadAppFonts;

Map<String, dynamic> _page(int id, String title) => {
  'node': {
    'id': id,
    'title': title,
    'media_type': 'tv',
    'status': 'finished_airing',
    'num_episodes': 12,
    'start_date': '2023-09-29',
    'alternative_titles': <String, dynamic>{},
  },
};

void main() {
  late Directory folder;
  late Databases databases;
  late ProviderContainer container;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_quick_layer_test');
    databases = await openDatabases(folder);
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: 'a',
            status: 'completed',
            addedAt: 1,
            progressChangedAt: 1,
            name: const Value('Frieren'),
          ),
        );
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'data': [
            _page(5, 'Frieren Recap'),
            _page(6, 'Frieren Prologue'),
            for (var i = 1; i <= 10; i++) _page(10 + i, 'Frieren Extra $i'),
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    container = ProviderContainer(
      overrides: [
        servicesProvider.overrideWithValue(
          Services(
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
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> pumpLayer(WidgetTester tester) async {
    await loadAppFonts();
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MediaQuery(
          data: MediaQueryData(size: Size(1100, 700)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(children: [QuickSearchLayer()]),
          ),
        ),
      ),
    );
  }

  // the databases are real files, so their reads need real time
  Future<void> openIt(WidgetTester tester) async {
    await tester.runAsync(
      () => container.read(quickSearchProvider.notifier).open(),
    );
    await tester.pump();
  }

  Future<void> typeIt(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(EditableText), text);
    await tester.pump();
    // the pause before the online search, then the search and its lookups
    await tester.pump(quickSearchDebounce);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  testWidgets('shows nothing until it is opened', (tester) async {
    await pumpLayer(tester);
    expect(find.text('Type a title'), findsNothing);
  });

  testWidgets('opens on the recent entries with the footer', (tester) async {
    await pumpLayer(tester);
    await openIt(tester);
    expect(find.text('Type a title'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Frieren'), findsOneWidget);
    expect(find.text('Browse all'), findsOneWidget);
    expect(find.byType(SweepButton), findsOneWidget);
    expect(find.text('Screenshot'), findsOneWidget);
  });

  testWidgets('typing shows your list, then everything else', (tester) async {
    await pumpLayer(tester);
    await openIt(tester);
    await tester.enterText(find.byType(EditableText), 'frieren');
    await tester.pump();
    // the list answers at once; skeleton rows hold the space for the rest
    expect(find.text('Your list'), findsOneWidget);
    expect(find.text('All anime'), findsOneWidget);
    expect(find.text('Frieren Recap'), findsNothing);
    await tester.pump(quickSearchDebounce);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('Frieren Recap'), findsOneWidget);
    expect(find.text('Frieren Prologue'), findsOneWidget);
  });

  testWidgets('Escape closes it', (tester) async {
    await pumpLayer(tester);
    await openIt(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(container.read(quickSearchProvider).open, isFalse);
    expect(find.text('Type a title'), findsNothing);
  });

  testWidgets('the arrow keys move the highlight', (tester) async {
    await pumpLayer(tester);
    await openIt(tester);
    await typeIt(tester, 'frieren');
    expect(container.read(quickSearchProvider).focus, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(container.read(quickSearchProvider).focus, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(container.read(quickSearchProvider).focus, 0);
  });

  testWidgets('Load more is reached with the keys and shows more rows', (
    tester,
  ) async {
    await pumpLayer(tester);
    await openIt(tester);
    await typeIt(tester, 'frieren');
    expect(find.text('10 more'), findsOneWidget);
    expect(find.text('Frieren Extra 9'), findsNothing);
    // one row on the list, four found online, then Load more
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('Frieren Extra 9'), findsOneWidget);
    // the highlight moved to the first new row, not back to the top
    expect(container.read(quickSearchProvider).focus, 5);
  });
}
