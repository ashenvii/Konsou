import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/library/title_language.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/franchise_scan.dart';
import 'package:konsou/mal/matching.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/mal/search_request.dart';
import 'package:konsou/mal/trickle.dart';
import 'package:sqlite3/sqlite3.dart';

// Counts the MAL calls one user's list makes, by cause: a cold start, then 90
// days of use on a fake clock. MAL is a fake that serves the responses saved in
// a copy of a real details.db, so relations are real; a title it never saved
// answers as a bare finished series with no relations.
//
// Run: KONSOU_SIM=<folder with copies of konsou.db and details.db>
//   flutter test test/sim/request_load_test.dart
final _source = Platform.environment['KONSOU_SIM'];

const _days = 90;

// detail pages and quick panels opened a day
const _opensPerDay = 18;

void main() {
  test(
    'request load of one user over 90 days',
    () async {
      final folder = Directory.systemTemp.createTempSync('konsou_sim');
      addTearDown(() => folder.deleteSync(recursive: true));
      File('$_source/konsou.db').copySync('${folder.path}/konsou.db');
      final databases = await openDatabases(folder);
      addTearDown(databases.close);

      final real = sqlite3.open('$_source/details.db', mode: OpenMode.readOnly);
      final saved = {
        for (final row in real.select(
          "SELECT provider_id, json FROM detail WHERE provider = 'mal'",
        ))
          row['provider_id'] as int: jsonEncode(
            (jsonDecode(row['json'] as String) as Map<String, dynamic>)
              ..putIfAbsent('num_scoring_users', () => 100),
          ),
      };
      real.close();

      var now = DateTime.now();
      var phase = 'cold';
      final calls = <String, int>{};
      final client = MockClient((request) async {
        final last = request.url.pathSegments.last;
        if (last == 'anime') {
          calls.update('$phase search', (n) => n + 1, ifAbsent: () => 1);
          return http.Response('{"data": []}', 200);
        }
        final malId = int.parse(last);
        final full = request.url.queryParameters['fields']!.contains(
          'synopsis',
        );
        final kind = '$phase ${full ? 'full' : 'short'}';
        calls.update(kind, (n) => n + 1, ifAbsent: () => 1);
        return http.Response(
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
              }),
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

      // the list's MAL ids, and those of what is being followed
      final everything = <int>[];
      final followed = <int>[];
      for (final row in await databases.record.customSelect('''
        SELECT entry_reference.provider_id AS id, entry.status
        FROM entry JOIN entry_reference USING (entry_id)
        WHERE entry_reference.provider = 'mal'
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

      await trickle.run();
      phase = 'cold scan';
      await scan.run();
      final out = StringBuffer('\nCOLD START\n');
      calls.forEach((kind, count) => out.writeln('  $kind $count'));
      out.writeln('  total ${calls.values.fold(0, (a, b) => a + b)}');
      calls.clear();

      final random = Random(42);
      final scanByDay = List.filled(_days, 0);
      var busiestScan = 0;
      for (var day = 0; day < _days; day++) {
        now = now.add(const Duration(days: 1));
        phase = 'day background';
        await trickle.run();
        phase = 'day scan';
        final before = calls['day scan short'] ?? 0;
        await scan.run();
        scanByDay[day] = (calls['day scan short'] ?? 0) - before;
        busiestScan = max(busiestScan, scanByDay[day]);
        phase = 'day open';
        // most opens are of what is being followed, some are of anything
        for (var i = 0; i < _opensPerDay; i++) {
          final pool = random.nextDouble() < 0.6 ? followed : everything;
          final malId = pool[random.nextInt(pool.length)];
          final details = await readTitleDetails(
            databases,
            malId,
            TitleLanguage.romaji,
          );
          if (details == null || details.needsFetch(now)) {
            await detailRequest.fetch(malId, lane: Lane.page, full: true);
          }
        }
      }

      out.writeln('\nDAYS 1 to $_days');
      calls.forEach((kind, count) => out.writeln('  $kind $count'));
      out.writeln('  total ${calls.values.fold(0, (a, b) => a + b)}');
      out.writeln('  busiest scan day $busiestScan');
      out.writeln(
        '  scan by week ${[for (var week = 0; week < _days ~/ 7; week++) scanByDay.skip(week * 7).take(7).fold(0, (a, b) => a + b)]}',
      );
      // ignore: avoid_print
      print(out);
    },
    skip: _source == null
        ? 'set KONSOU_SIM to a folder holding copies of konsou.db and details.db'
        : false,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
