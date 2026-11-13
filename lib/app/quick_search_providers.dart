import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../library/earlier_titles.dart';
import '../library/entry_status.dart';
import '../library/library_row.dart';
import '../library/load_library.dart';
import '../library/quick_search.dart';
import '../library/title_language.dart';
import '../mal/request_gate.dart';
import '../mal/search_request.dart';
import '../search/entry_search.dart';
import 'library_providers.dart';
import 'providers.dart';

part 'quick_search_providers.g.dart';

/// A short pause after the last key, so the online search runs once per word
/// and not once per letter.
const quickSearchDebounce = Duration(milliseconds: 350);

@Riverpod(keepAlive: true)
class QuickSearch extends _$QuickSearch {
  Timer? _debounce;

  // a newer search or a close makes an older answer stale
  int _run = 0;

  // online results already fetched, and the words they were fetched for
  int _offset = 0;
  String _searched = '';

  EntrySearch? _search;
  Map<String, LibraryEntry> _entries = {};
  TitleLanguage _language = TitleLanguage.romaji;

  @override
  QuickState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const QuickState();
  }

  Future<void> open() async {
    if (state.open) return;
    state = const QuickState(open: true);
    await _readList();
    if (!state.open) return;
    state = state.copyWith(recent: await _recentRows());
    if (state.typing) setQuery(state.query);
  }

  void close() {
    _debounce?.cancel();
    _run++;
    state = const QuickState();
  }

  void toggle() => state.open ? close() : open();

  void setQuery(String text) {
    final query = text.trim();
    _debounce?.cancel();
    final run = ++_run;
    _offset = 0;
    if (query.isEmpty) {
      state = state.copyWith(
        query: '',
        mine: const [],
        online: const [],
        searching: false,
        onlineMore: false,
        failed: false,
        mineShown: quickFirst,
        onlineShown: quickFirst,
        focus: 0,
      );
      return;
    }
    final online =
        query.runes.length >= minQueryLength &&
        ref.read(servicesProvider).matching != null;
    state = state.copyWith(
      query: query,
      mine: _mineRows(query),
      online: const [],
      searching: online,
      onlineMore: false,
      failed: false,
      mineShown: quickFirst,
      onlineShown: quickFirst,
      focus: 0,
    );
    if (online) {
      _debounce = Timer(quickSearchDebounce, () => _fetch(query, run));
    }
  }

  /// Shows the next page of both groups, and asks online for more when what it
  /// has runs out. The highlight moves to the first row that was not there.
  Future<void> loadMore() async {
    final before = state;
    // a second Enter while the first page is still coming asks for nothing
    if (!before.hasMore) return;
    final run = _run;
    final mineGrew = before.mine.length > before.mineShown;
    final target = mineGrew ? before.shownMine.length : before.rows.length;
    state = before.copyWith(
      mineShown: before.mineShown + quickPage,
      onlineShown: before.onlineShown + quickPage,
      focus: target,
    );
    if (before.onlineMore && before.online.length < state.onlineShown) {
      state = state.copyWith(searching: true);
      await _fetch(before.query, run);
    }
    if (run != _run) return;
    final last = state.rows.length - 1;
    if (state.focus > last) state = state.copyWith(focus: max(0, last));
  }

  void moveFocus(int step) {
    final count = state.itemCount;
    if (count == 0) return;
    state = state.copyWith(focus: (state.focus + step).clamp(0, count - 1));
  }

  void focusRow(int index) {
    if (index != state.focus) state = state.copyWith(focus: index);
  }

  /// Enter on the highlighted row, or a click on Load more.
  void activate() {
    final rows = state.rows;
    if (state.hasMore && state.focus == rows.length) {
      loadMore();
      return;
    }
    if (state.focus < rows.length) openRow(rows[state.focus]);
  }

  /// The Detail page is not built yet (ticket 007d3), so opening a title only
  /// closes the search until it exists.
  void openRow(QuickRow row) => close();

  /// The checkbox: complete a title on the list or take that back, or add a
  /// title that is not on the list as Completed.
  Future<void> toggleComplete(QuickRow row) async {
    final actions = ref.read(entryActionsProvider);
    final entryId = row.entryId;
    final malId = row.malId;
    if (entryId != null) {
      row.completed
          ? await actions.uncheck(entryId)
          : await actions.setStatus(entryId, EntryStatus.completed);
    } else if (malId != null) {
      await actions.addCompleted(
        EarlierTitle(
          malId: malId,
          name: row.name,
          isExtra: false,
          episodes: row.episodes,
        ),
        airing: row.airing,
      );
    }
    await _refreshAfterEdit();
  }

  Future<void> _fetch(String query, int run) async {
    final request = ref.read(servicesProvider).matching?.searchRequest;
    final search = _search;
    if (request == null || search == null) {
      if (run == _run) state = state.copyWith(searching: false);
      return;
    }
    final asked = _offset == 0 ? query : _searched;
    var pages = await request.search(
      asked,
      lane: Lane.screen,
      limit: quickPage,
      offset: _offset,
    );
    var used = asked;
    if (pages != null && pages.isEmpty && _offset == 0) {
      // nothing found: try the words as the titles Konsou knows spell them
      final corrected = search.correctedQuery(query);
      if (corrected != null) {
        pages = await request.search(
          corrected,
          lane: Lane.screen,
          limit: quickPage,
        );
        used = corrected;
      }
    }
    if (run != _run) return;
    if (pages == null) {
      state = state.copyWith(searching: false, failed: true);
      return;
    }
    final unlisted = (await search.dropListed([
      for (final page in pages) page['id'] as int,
    ])).toSet();
    if (run != _run) return;
    _searched = used;
    _offset += pages.length;
    state = state.copyWith(
      online: [
        ...state.online,
        for (final page in pages)
          if (unlisted.contains(page['id'] as int))
            quickRowFromPage(page, _language),
      ],
      onlineMore: pages.length >= quickPage,
      searching: false,
      failed: false,
    );
  }

  Future<void> _readList() async {
    final databases = ref.read(servicesProvider).databases;
    _language = await readTitleLanguage(databases.record);
    final entries = await loadLibraryEntries(databases, _language);
    _entries = {for (final entry in entries) entry.entryId: entry};
    _search = await ref.read(entrySearchProvider.future);
  }

  Future<List<QuickRow>> _recentRows() async => [
    for (final id in await _search!.findRecent())
      if (_entries[id] case final entry?) quickRowFromEntry(entry),
  ];

  List<QuickRow> _mineRows(String query) => [
    for (final id in _search?.findEntries(query) ?? const <String>[])
      if (_entries[id] case final entry?) quickRowFromEntry(entry),
  ];

  /// After an edit: the rows read again, and a title just added moves from the
  /// online group to the list.
  Future<void> _refreshAfterEdit() async {
    await _readList();
    if (!state.open) return;
    final stillOnline = (await _search!.dropListed([
      for (final row in state.online) ?row.malId,
    ])).toSet();
    state = state.copyWith(
      recent: await _recentRows(),
      mine: state.typing ? _mineRows(state.query) : null,
      online: [
        for (final row in state.online)
          if (stillOnline.contains(row.malId)) row,
      ],
    );
  }
}
