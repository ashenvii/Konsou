import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:konsou/app/keys.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/services.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_google.dart';

void main() {
  late Directory folder;
  late Databases databases;
  late Services services;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    folder = Directory.systemTemp.createTempSync('konsou_library_providers');
    databases = await openDatabases(folder);
    // no keys: no background work, only the databases and the streams
    services = Services(
      databases: databases,
      keys: const Keys(
        malClientId: '',
        googleClientId: '',
        googleClientSecret: '',
      ),
      coversFolder: Directory('${folder.path}/covers'),
      client: http.Client(),
      tokenStore: MemoryTokenStore(),
      openBrowser: (_) async {},
    );
    container = ProviderContainer(
      overrides: [servicesProvider.overrideWithValue(services)],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addEntry(String id, String status, {String? name}) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: id,
            status: status,
            name: Value(name),
            addedAt: 1,
            progressChangedAt: 1,
          ),
        );
  }

  test('the rows are the folded entries, by the saved name', () async {
    await addEntry('a', 'watching', name: 'Alpha');
    await addEntry('b', 'completed', name: 'Bravo');
    final rows = await container.read(libraryRowsProvider.future);
    expect([for (final row in rows) row.name]..sort(), ['Alpha', 'Bravo']);
  });

  test('an edit through the provider changes the record', () async {
    await addEntry('a', 'watching', name: 'Alpha');
    await container.read(entryEditsProvider).setStatus('a', EntryStatus.onHold);
    container.invalidate(libraryRowsProvider);
    final rows = await container.read(libraryRowsProvider.future);
    expect(rows.single.status, 'on_hold');
  });

  test('rows reload on their own when the background work saves', () async {
    await addEntry('a', 'watching', name: 'Alpha');
    final sub = container.listen(libraryRowsProvider, (_, _) {});
    addTearDown(sub.close);
    expect((await container.read(libraryRowsProvider.future)).length, 1);
    await addEntry('b', 'watching', name: 'Bravo');
    // the same signal the trickle sends after each title
    services.notifyDataChanged();
    await Future<void>.delayed(
      libraryReloadGap + const Duration(milliseconds: 200),
    );
    expect((await container.read(libraryRowsProvider.future)).length, 2);
  });

  test('tab and sort start at All and Recent and keep what is picked', () {
    expect(container.read(libraryTabChoiceProvider), LibraryTab.all);
    expect(container.read(librarySortChoiceProvider), LibrarySort.recent);
    container
        .read(libraryTabChoiceProvider.notifier)
        .select(LibraryTab.planned);
    container
        .read(librarySortChoiceProvider.notifier)
        .select(LibrarySort.title);
    expect(container.read(libraryTabChoiceProvider), LibraryTab.planned);
    expect(container.read(librarySortChoiceProvider), LibrarySort.title);
  });

  test('the layout is grid until picked, then remembered', () async {
    expect(
      await container.read(libraryLayoutChoiceProvider.future),
      LibraryLayout.grid,
    );
    await container
        .read(libraryLayoutChoiceProvider.notifier)
        .select(LibraryLayout.list);
    final fresh = ProviderContainer(
      overrides: [servicesProvider.overrideWithValue(services)],
    );
    addTearDown(fresh.dispose);
    expect(
      await fresh.read(libraryLayoutChoiceProvider.future),
      LibraryLayout.list,
    );
  });
}
