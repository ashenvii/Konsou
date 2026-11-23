import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/countdown.dart';
import '../library/entry_edits.dart';
import '../library/library_row.dart';
import '../library/library_view.dart';
import '../library/load_library.dart';
import '../search/entry_search.dart';
import 'entry_actions.dart';
import 'providers.dart';
import 'toast_host.dart';

part 'library_providers.g.dart';

const libraryReloadGap = Duration(seconds: 10);

const libraryScreenReloadGap = Duration(milliseconds: 1500);

@riverpod
Future<List<LibraryRow>> libraryRows(Ref ref) async {
  final services = ref.watch(servicesProvider);
  // one reload per gap, not one per save
  final slow = Countdown(onDone: ref.invalidateSelf);
  final quick = Countdown(onDone: ref.invalidateSelf);
  final listener = services.dataChanged.listen((_) {
    if (!slow.running) slow.start(libraryReloadGap);
  });
  final screenListener = services.screenDataChanged.listen((_) {
    if (!quick.running) quick.start(libraryScreenReloadGap);
  });
  ref.onDispose(() {
    slow.dispose();
    quick.dispose();
    listener.cancel();
    screenListener.cancel();
  });
  final databases = services.databases;
  return loadLibraryRows(databases, await readTitleLanguage(databases.record));
}

@Riverpod(keepAlive: true)
EntryEdits entryEdits(Ref ref) {
  final services = ref.watch(servicesProvider);
  return EntryEdits(
    databases: services.databases,
    onChanged: () => services.sync?.noteChange(),
  );
}

@Riverpod(keepAlive: true)
EntryActions entryActions(Ref ref) {
  final host = ref.watch(toastHostProvider.notifier);
  return EntryActions(
    databases: ref.watch(servicesProvider).databases,
    edits: ref.watch(entryEditsProvider),
    show: host.show,
    answerReview: host.answerReview,
    onEdited: () => ref.invalidate(libraryRowsProvider),
  );
}

@Riverpod(keepAlive: true)
class LibraryTabChoice extends _$LibraryTabChoice {
  @override
  LibraryTab build() => LibraryTab.all;

  void select(LibraryTab tab) {
    state = tab;
    // rows an edit left in view only stay until the tab changes
    ref.invalidate(libraryKeptProvider);
  }
}

@riverpod
class LibraryKept extends _$LibraryKept {
  @override
  Set<String> build() => {};

  void keep(String entryId) => state = {...state, entryId};
}

@riverpod
class LibraryFindChoice extends _$LibraryFindChoice {
  @override
  String? build() => null;

  void open() => state ??= '';

  void change(String text) => state = text;

  void close() => state = null;
}

@riverpod
Future<EntrySearch> entrySearch(Ref ref) async {
  ref.watch(libraryRowsProvider);
  final search = EntrySearch(ref.watch(servicesProvider).databases);
  await search.refresh();
  return search;
}

/// The search index for a one-off read. Nothing may be watching it, so it is
/// held while it builds; otherwise it would be disposed before it is done.
Future<EntrySearch> readEntrySearch(Ref ref) async {
  final subscription = ref.listen(entrySearchProvider.future, (_, _) {});
  try {
    return await subscription.read();
  } finally {
    subscription.close();
  }
}

@riverpod
Future<Set<String>?> libraryFindMatches(Ref ref) async {
  final query = ref.watch(libraryFindChoiceProvider)?.trim() ?? '';
  if (query.isEmpty) return null;
  final search = await ref.watch(entrySearchProvider.future);
  return search.findEntries(query).toSet();
}

@Riverpod(keepAlive: true)
class LibraryHoveredRow extends _$LibraryHoveredRow {
  @override
  String? build() => null;

  void set(String entryId) => state = entryId;

  void clear(String entryId) {
    if (state == entryId) state = null;
  }
}

@Riverpod(keepAlive: true)
class LibraryLetterJump extends _$LibraryLetterJump {
  @override
  ({String letter, int count})? build() => null;

  void to(String letter) =>
      state = (letter: letter, count: (state?.count ?? 0) + 1);
}

const _sortKey = 'library.sort';

@Riverpod(keepAlive: true)
class LibrarySortChoice extends _$LibrarySortChoice {
  @override
  Future<LibrarySort> build() =>
      _readChoice(_sortKey, LibrarySort.values, LibrarySort.recent);

  Future<void> select(LibrarySort sort) async {
    state = AsyncData(sort);
    await _saveChoice(_sortKey, sort);
  }
}

const _layoutKey = 'library.layout';

@Riverpod(keepAlive: true)
class LibraryLayoutChoice extends _$LibraryLayoutChoice {
  @override
  Future<LibraryLayout> build() =>
      _readChoice(_layoutKey, LibraryLayout.values, LibraryLayout.grid);

  Future<void> select(LibraryLayout layout) async {
    state = AsyncData(layout);
    await _saveChoice(_layoutKey, layout);
  }
}

Future<T> _readChoice<T extends Enum>(
  String key,
  List<T> values,
  T fallback,
) async {
  try {
    final saved = (await SharedPreferences.getInstance()).getString(key);
    return values.asNameMap()[saved] ?? fallback;
  } on Exception {
    return fallback;
  }
}

Future<void> _saveChoice(String key, Enum choice) async {
  try {
    await (await SharedPreferences.getInstance()).setString(key, choice.name);
  } on Exception {
    // not remembered, but it still applies
  }
}
