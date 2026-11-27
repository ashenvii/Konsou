import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/franchise_scan.dart';
import 'package:konsou/mal/matching.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/mal/search_request.dart';
import 'package:konsou/mal/trickle.dart';
import 'package:sqlite3/sqlite3.dart';

// Counts the MAL calls one user's list makes, by cause: a cold start, then 90
// days of use on a fake clock. MAL is a fake that serves the responses saved in
// a copy of a real details.db, so sizes and relations are real; a title it never
// saved answers as a bare finished series with no relations.
//
// Run: KONSOU_SIM=<folder with copies of konsou.db and details.db>
//   flutter test test/sim/request_load_test.dart
final Object _skip = Platform.environment['KONSOU_SIM'] == null
    ? 'set KONSOU_SIM to a folder holding copies of konsou.db and details.db'
    : false;

const _days = 90;
const _opensPerDay = 8;
const _panelsPerDay = 10;

void main() {
  test(
    'request load of one user over 90 days',
    () async {
      final source = Directory(Platform.environment['KONSOU_SIM']!);
      final folder = Directory.systemTemp.createTempSync('konsou_sim');
      addTearDown(() => folder.deleteSync(recursive: true));
      File('${source.path}/konsou.db').copySync('${folder.path}/konsou.db');
      final databases = await openDatabases(folder);
      addTearDown(databases.close);

      final saved = <int, String>{};
      final real = sqlite3.open(
        '${source.path}/details.db',
        mode: OpenMode.readOnly,
      );
      for (final row in real.select(
        "SELECT provider_id, json FROM detail WHERE provider = 'mal'",
      )) {
        final json = jsonDecode(row['json'] as String) as Map<String, dynamic>;
        json.putIfAbsent('num_scoring_users', () => 100);
        saved[row['provider_id'] as int] = jsonEncode(json);
      }
      real.close();

      var now = DateTime.now();
      var phase = 'cold';
      final calls = <String, int>{};
      final bytes = <String, int>{};
      void note(String kind, int size) {
        final key = '$phase $kind';
        calls[key] = (calls[key] ?? 0) + 1;
        bytes[key] = (bytes[key] ?? 0) + size;
      }

      final client = MockClient((request) async {
        final last = request.url.pathSegments.last;
        if (last == 'anime') {
          note('search', 300);
          return http.Response('{"data": []}', 200);
        }
        final malId = int.parse(last);
        final full = request.url.queryParameters['fields']!.contains(
          'synopsis',
        );
        final body =
            saved[malId] ??
            jsonEncode({
              'id': malId,
              'title': 'Title $malId',
              'num_scoring_users': 10,
              'mean': 7.0,
              'status': 'finished_airing',
              'media_type': 'tv',
              'num_episodes': 12,
              'start_date': '2015-01-01',
              'related_anime': <Object>[],
            });
        // the measured sizes: 1.4 KB short, 7.8 KB full
        note(full ? 'full' : 'short', full ? 7800 : 1400);
        return http.Response(
          body,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final gate = RequestGate(wait: (_) async {});
      final detailRequest = DetailRequest(
        clientId: 'sim',
        client: client,
        gate: gate,
        details: databases.details,
        now: () => now,
      );
      final trickle = Trickle(
        record: databases.record,
        detailRequest: detailRequest,
        matching: Matching(
          databases: databases,
          searchRequest: SearchRequest(
            clientId: 'sim',
            client: client,
            gate: gate,
          ),
          detailRequest: detailRequest,
          now: () => now,
        ),
        now: () => now,
      );
      final scan = FranchiseScan(
        databases: databases,
        detailRequest: detailRequest,
        now: () => now,
      );

      // the list's MAL ids, the ones being followed first
      final followed = <int>[];
      final everything = <int>[];
      for (final row in await databases.record.customSelect('''
      SELECT entry_reference.provider_id AS id, entry.status AS status
      FROM entry JOIN entry_reference ON entry_reference.entry_id = entry.entry_id
        AND entry_reference.provider = 'mal'
      ''').get()) {
        final id = row.read<int>('id');
        everything.add(id);
        if (const {
          'watching',
          'rewatching',
          'plan_to_watch',
          'on_hold',
        }.contains(row.read<String>('status'))) {
          followed.add(id);
        }
      }

      Future<void> open(int malId) async {
        final details = databases.details;
        final row =
            await (details.select(details.detail)..where(
                  (row) =>
                      row.provider.equals('mal') & row.providerId.equals(malId),
                ))
                .getSingleOrNull();
        final wanted =
            row == null ||
            !row.isFull ||
            isStale(
              airingStatus: row.airingStatus,
              fetchedAt: row.fetchedAt,
              now: now,
            );
        if (wanted) {
          await detailRequest.fetch(malId, lane: Lane.page, full: true);
        }
      }

      // the cold start: the trickle, matching, then the first scan
      await trickle.run();
      phase = 'cold scan';
      await scan.run();
      final cold = Map<String, int>.of(calls);

      final random = Random(42);
      final perDay = <String, List<int>>{};
      for (var day = 1; day <= _days; day++) {
        now = now.add(const Duration(days: 1));
        final before = Map<String, int>.of(calls);
        phase = 'day background';
        await trickle.run();
        phase = 'day scan';
        await scan.run();
        phase = 'day open';
        // most opens are of what is being followed, some are of anything
        for (var i = 0; i < _opensPerDay + _panelsPerDay; i++) {
          final pool = random.nextDouble() < 0.6 ? followed : everything;
          await open(pool[random.nextInt(pool.length)]);
        }
        for (final key in calls.keys) {
          if (!key.startsWith('day')) continue;
          (perDay[key] ??= List.filled(_days, 0))[day - 1] =
              calls[key]! - (before[key] ?? 0);
        }
      }

      final out = StringBuffer('\nCOLD START (one time)\n');
      for (final key in cold.keys.toList()..sort()) {
        out.writeln(
          '  ${key.padRight(22)} ${cold[key].toString().padLeft(6)}'
          '  ${(bytes[key]! / 1e6).toStringAsFixed(1)} MB',
        );
      }
      out.writeln('  total ${cold.values.fold(0, (a, b) => a + b)}');
      out.writeln('\nDAYS 1 to $_days, per kind');
      for (final key in perDay.keys.toList()..sort()) {
        final list = perDay[key]!;
        int sum(int from, int to) =>
            list.sublist(from, to).fold(0, (a, b) => a + b);
        out.writeln(
          '  ${key.padRight(22)} total ${sum(0, _days).toString().padLeft(6)}'
          '  days 1-30 ${sum(0, 30).toString().padLeft(5)}'
          '  31-60 ${sum(30, 60).toString().padLeft(5)}'
          '  61-90 ${sum(60, 90).toString().padLeft(5)}'
          '  busiest day ${list.reduce(max)}',
        );
      }
      final scanDays = List.filled(_days, 0);
      for (final MapEntry(:key, :value) in perDay.entries) {
        if (!key.startsWith('day scan')) continue;
        for (var i = 0; i < _days; i++) {
          scanDays[i] += value[i];
        }
      }
      out.writeln(
        '  scan by week: ${[for (var w = 0; w < 12; w++) scanDays.sublist(w * 7, w * 7 + 7).fold(0, (a, b) => a + b)]}',
      );
      // ignore: avoid_print
      print(out);
      expect(cold.isNotEmpty, isTrue);
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
