import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:konsou/app/keys.dart';
import 'package:konsou/app/services.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/sync/google_sign_in.dart';

import '../support/fake_google.dart';

const _allKeys = Keys(
  malClientId: 'mal',
  googleClientId: 'google',
  googleClientSecret: 'secret',
);

void main() {
  late Directory folder;
  late Databases databases;
  late FakeGoogle google;
  late MemoryTokenStore store;
  late List<String> asked;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_services_test');
    databases = await openDatabases(folder);
    google = FakeGoogle();
    store = MemoryTokenStore();
    asked = [];
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addEntry(String id, {int? malId}) async {
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

  void signIn() => store.tokens = GoogleTokens(
    accessToken: google.validToken,
    refreshToken: 'refresh-1',
    expiresAt: DateTime.now()
        .add(const Duration(hours: 1))
        .millisecondsSinceEpoch,
    email: 'owner@example.com',
  );

  http.Client routed({void Function()? onMal}) =>
      _RoutedClient(google.client, asked, onMal: onMal);

  Services build(Keys keys, {void Function()? onMal}) => Services(
    databases: databases,
    keys: keys,
    coversFolder: Directory('${folder.path}/covers'),
    client: routed(onMal: onMal),
    tokenStore: store,
    openBrowser: (_) async {},
    gate: RequestGate(wait: (_) async {}),
  );

  test('syncs first, then fetches details', () async {
    await addEntry('a', malId: 1);
    signIn();
    final services = build(_allKeys);
    await services.start();
    final firstMal = asked.indexWhere((line) => line.startsWith('mal'));
    expect(asked.first, 'google');
    expect(asked.lastIndexOf('google'), lessThan(firstMal));
    expect(asked, contains('mal 1'));
    expect(google.file('record.json'), isNotNull);
  });

  test('without a saved sign-in it fetches details and never syncs', () async {
    await addEntry('a', malId: 1);
    await build(_allKeys).start();
    expect(asked, ['mal 1']);
  });

  test('without a MAL id it syncs and asks MAL nothing', () async {
    await addEntry('a', malId: 1);
    signIn();
    await build(
      const Keys(
        malClientId: '',
        googleClientId: 'google',
        googleClientSecret: 'secret',
      ),
    ).start();
    expect(asked.where((line) => line.startsWith('mal')), isEmpty);
    expect(google.file('record.json'), isNotNull);
  });

  test('without a Google id it never touches Google', () async {
    await addEntry('a', malId: 1);
    signIn();
    final services = build(
      const Keys(
        malClientId: 'mal',
        googleClientId: '',
        googleClientSecret: '',
      ),
    );
    await services.start();
    expect(asked, ['mal 1']);
    expect(services.sync, isNull);
  });

  Future<void> addDetailWithCover(int malId) {
    final details = databases.details;
    return details
        .into(details.detail)
        .insert(
          DetailCompanion.insert(
            provider: 'mal',
            providerId: malId,
            fetchedAt: 1,
            json:
                '{"main_picture": {"medium": '
                '"https://cdn.myanimelist.net/images/anime/1/$malId.webp"}}',
          ),
        );
  }

  test('details come first, then covers', () async {
    await addEntry('a', malId: 1);
    await addEntry('b', malId: 2);
    await addDetailWithCover(2);
    await build(_allKeys).start();
    expect(asked, ['mal 1', 'cover 2.webp']);
  });

  test(
    'stop during the trickle leaves the covers and the scan alone',
    () async {
      await addEntry('a', malId: 1);
      await addEntry('b', malId: 2);
      await addDetailWithCover(2);
      late Services services;
      services = build(_allKeys, onMal: () => services.stop());
      await services.start();
      expect(asked, ['mal 1']);
    },
  );

  test('screens hear about saved covers and fresh data', () async {
    await addEntry('a', malId: 1);
    await addDetailWithCover(1);
    final services = build(_allKeys);
    final covers = <int>[];
    var changes = 0;
    services.coverSaved.listen(covers.add);
    services.dataChanged.listen((_) => changes++);
    await services.start();
    await Future<void>.delayed(Duration.zero);
    expect(covers, [1]);
    // after sync, after the cover, and at the end of the chain
    expect(changes, greaterThanOrEqualTo(2));
  });

  test('stop ends the chain and runs the close sync', () async {
    signIn();
    final services = build(_allKeys);
    await services.start();
    await addEntry('late');
    await services.stop();
    expect(google.file('record.json')!.content, contains('late'));
  });
}

/// MAL answers go to [asked]; everything else is the fake Google.
class _RoutedClient extends http.BaseClient {
  _RoutedClient(this._google, this._asked, {this.onMal});

  /// Called when a MAL request arrives, to act in the middle of the chain.
  final void Function()? onMal;

  final http.Client _google;
  final List<String> _asked;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host == 'cdn.myanimelist.net') {
      _asked.add('cover ${request.url.pathSegments.last}');
      return http.StreamedResponse(
        Stream.value(const [1, 2, 3]),
        200,
        headers: {'content-type': 'image/webp'},
      );
    }
    if (request.url.host != 'api.myanimelist.net') {
      _asked.add('google');
      return _google.send(request);
    }
    _asked.add('mal ${request.url.pathSegments.last}');
    onMal?.call();
    return http.StreamedResponse(Stream.value(const []), 404);
  }
}
