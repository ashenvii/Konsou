import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../components/countdown.dart';
import '../data/databases.dart';
import '../detail/provider_page.dart';
import '../detail/streamer_mode.dart';
import '../detail/title_details.dart';
import '../detail/title_entry.dart';
import '../detail/recommended_titles.dart';
import '../detail/watch_order.dart';
import '../library/load_library.dart';
import '../mal/detail_request.dart';
import '../mal/matching.dart';
import '../mal/search_request.dart';
import 'library_providers.dart';
import 'providers.dart';
import 'quick_search_providers.dart';
import 'services.dart';

export '../mal/matching.dart' show maxSuggestions;

part 'detail_providers.g.dart';

enum DetailFetch { idle, running, offline, failed, gone }

class DetailPageData {
  const DetailPageData({
    this.details,
    this.entry,
    this.fetch = DetailFetch.idle,
    this.isHidden = false,
  });

  final TitleDetails? details;
  final TitleEntry? entry;
  final DetailFetch fetch;

  final bool isHidden;

  DetailPageData withFetch(DetailFetch fetch) => DetailPageData(
    details: details,
    entry: entry,
    fetch: fetch,
    isHidden: isHidden,
  );
}

void _reloadOnEdit(Ref ref, Databases databases, void Function() reload) {
  final record = databases.record;
  final listener = record
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          record.entry,
          record.entryReference,
          record.completion,
        ]),
      )
      .listen((_) => reload());
  ref.onDispose(listener.cancel);
}

@riverpod
class DetailPage extends _$DetailPage {
  @override
  Future<DetailPageData> build(int malId, {String? entryId}) async {
    final services = ref.watch(servicesProvider);
    _reloadOnEdit(ref, services.databases, _reload);
    final saved = await _read();
    final wantsFetch =
        services.detailRequest != null &&
        (saved.details?.needsFetch(DateTime.now()) ?? true);
    _fetchState = wantsFetch ? DetailFetch.running : DetailFetch.idle;
    if (!wantsFetch) return saved;
    // after this build's value is in, so the fetch's answer is not overwritten
    Future(_fetch);
    return saved.withFetch(DetailFetch.running);
  }

  var _fetchState = DetailFetch.idle;

  // an edit's reload and the fetch both read, and the read started last wins,
  // so an older read never lands over a newer one
  var _reads = 0;

  Future<void> retry() async {
    final shown = state.value;
    if (shown == null || shown.fetch == DetailFetch.running) return;
    if (ref.read(servicesProvider).detailRequest == null) return;
    _fetchState = DetailFetch.running;
    state = AsyncData(shown.withFetch(DetailFetch.running));
    await _fetch();
  }

  Future<void> _fetch() async {
    if (!ref.mounted) return;
    final services = ref.read(servicesProvider);
    final request = services.detailRequest;
    if (request == null) return;
    final outcome = await request.fetch(
      malId,
      lane: Lane.page,
      full: true,
      wanted: () => ref.mounted,
    );
    if (!ref.mounted) return;
    if (outcome == FetchOutcome.fetched) services.notifyScreenDataChanged();
    _fetchState = switch (outcome) {
      FetchOutcome.fetched => DetailFetch.idle,
      FetchOutcome.gone => DetailFetch.gone,
      FetchOutcome.offline => DetailFetch.offline,
      FetchOutcome.failed => DetailFetch.failed,
    };
    await _reload();
  }

  Future<void> _reload() async {
    final read = ++_reads;
    final saved = await _read();
    if (!ref.mounted || read != _reads) return;
    state = AsyncData(saved.withFetch(_fetchState));
  }

  Future<DetailPageData> _read() async {
    final databases = ref.read(servicesProvider).databases;
    final (details, entry, streamerMode) = await (
      readTitleLanguage(databases.record)
          .then((language) => readTitleDetails(databases, malId, language)),
      readEntryOnPage(databases, malId, preferred: entryId),
      readStreamerMode(databases.record),
    ).wait;
    return DetailPageData(
      details: details,
      entry: entry,
      isHidden: isHiddenInStreamerMode(
        streamerMode: streamerMode,
        nsfw: details?.nsfw,
      ),
    );
  }
}

// a title fetched while the page is open may bring new relations or fill a
// card; every card fetched says so, so the reloads are gathered like the
// Library's
void _reloadOnNewData(Ref ref, Services services) {
  _reloadOnEdit(ref, services.databases, ref.invalidateSelf);
  final reload = Countdown(onDone: ref.invalidateSelf);
  final listener = services.screenDataChanged.listen((_) {
    if (!reload.running) reload.start(libraryScreenReloadGap);
  });
  ref.onDispose(() {
    reload.dispose();
    listener.cancel();
  });
}

@riverpod
Future<WatchOrder> watchOrder(Ref ref, int malId) async {
  final services = ref.watch(servicesProvider);
  _reloadOnNewData(ref, services);
  final databases = services.databases;
  return loadWatchOrder(
    databases,
    malId,
    await readTitleLanguage(databases.record),
  );
}

/// The titles MAL's users recommend after [malId], with what is saved of
/// each; the cards fetch the rest while they show.
@riverpod
Future<List<RecommendedTitle>> recommendedTitles(Ref ref, int malId) async {
  final services = ref.watch(servicesProvider);
  _reloadOnNewData(ref, services);
  final databases = services.databases;
  final language = await readTitleLanguage(databases.record);
  final details = await readTitleDetails(databases, malId, language);
  return loadRecommendedTitles(
    databases,
    details?.recommendations ?? const [],
    language,
    now: DateTime.now(),
  );
}

class NotLinkedPage {
  const NotLinkedPage({required this.entry, required this.suggestions});

  // null once the entry is removed
  final TitleEntry? entry;
  final List<ProviderPage> suggestions;
}

@riverpod
Future<NotLinkedPage> notLinkedPage(Ref ref, String entryId) async {
  final databases = ref.watch(servicesProvider).databases;
  _reloadOnEdit(ref, databases, ref.invalidateSelf);
  final details = databases.details;
  final listener = details
      .tableUpdates(TableUpdateQuery.onTable(details.matchSuggestion))
      .listen((_) => ref.invalidateSelf());
  ref.onDispose(listener.cancel);
  final (entry, suggestions) = await (
    readEntry(databases, entryId),
    readTitleLanguage(databases.record)
        .then((language) => readSuggestions(databases, entryId, language)),
  ).wait;
  return NotLinkedPage(entry: entry, suggestions: suggestions);
}

/// What the page picker and "Wrong title" do to an entry's link.
class PageLinking {
  PageLinking(this._matching, this._onChanged, this._onLooking);

  final Matching _matching;
  final void Function() _onChanged;
  final void Function(String entryId, {required bool looking}) _onLooking;

  Future<void> pick(String entryId, int malId) async {
    await _matching.linkEntry(entryId, malId, lane: Lane.page, full: true);
    _onChanged();
  }

  Future<void> declineAll(String entryId) =>
      _matching.declineSuggestions(entryId);

  /// Unlinks the entry and declines its page, then looks for the right one.
  /// [onUnlinked] runs as soon as the entry is off the page, before the
  /// search, which takes a moment.
  Future<void> replaceWrongTitle(
    String entryId, {
    void Function()? onUnlinked,
  }) async {
    await _matching.unlinkEntry(entryId);
    _onChanged();
    _onLooking(entryId, looking: true);
    onUnlinked?.call();
    try {
      await _matching.matchEntry(entryId, lane: Lane.page);
    } finally {
      _onLooking(entryId, looking: false);
    }
    _onChanged();
  }
}

/// The entries Konsou is looking up a page for right now, so their picker
/// can say so in place of "No suggestions".
@Riverpod(keepAlive: true)
class LookingForPage extends _$LookingForPage {
  @override
  Set<String> build() => {};

  void set(String entryId, {required bool looking}) =>
      state = looking ? {...state, entryId} : ({...state}..remove(entryId));
}

/// Null when no connection to MAL is set up, so nothing can be linked.
@Riverpod(keepAlive: true)
PageLinking? pageLinking(Ref ref) {
  final services = ref.watch(servicesProvider);
  final matching = services.matching;
  if (matching == null) return null;
  return PageLinking(matching, () {
    services.sync?.noteChange();
    services.notifyScreenDataChanged();
    ref.invalidate(libraryRowsProvider);
  }, ref.read(lookingForPageProvider.notifier).set);
}

class PickerSearchState {
  const PickerSearchState({
    this.query = '',
    this.results = const [],
    this.searching = false,
    this.failed = false,
    this.corrected,
  });

  final String query;
  final List<ProviderPage> results;
  final bool searching;
  final bool failed;

  /// The words searched for in place of the typed ones, when those found
  /// nothing.
  final String? corrected;

  bool get foundNothing =>
      !searching &&
      !failed &&
      results.isEmpty &&
      query.runes.length >= minQueryLength;
}

/// The page picker's search box: the typed MAL search with the typo help.
@riverpod
class PickerSearch extends _$PickerSearch {
  late final Countdown _wait = Countdown(onDone: _fetch);

  @override
  PickerSearchState build(String entryId) {
    ref.onDispose(_wait.dispose);
    return const PickerSearchState();
  }

  void setQuery(String text) {
    final query = text.trim();
    final online =
        query.runes.length >= minQueryLength &&
        ref.read(servicesProvider).matching != null;
    state = PickerSearchState(query: query, searching: online);
    online ? _wait.start(quickSearchDebounce) : _wait.cancel();
  }

  Future<void> _fetch() async {
    final query = state.query;
    final services = ref.read(servicesProvider);
    final databases = services.databases;
    // the language is local, so it is read while the search is out
    final (search, language) = await (
      readEntrySearch(ref),
      readTitleLanguage(databases.record),
    ).wait;
    final found = await services.matching!.searchPages(
      query,
      correct: search.correctedQuery,
    );
    // a newer search, or the page left, makes this answer stale
    if (!ref.mounted || state.query != query) return;
    if (found == null) {
      state = PickerSearchState(query: query, failed: true);
      return;
    }
    state = PickerSearchState(
      query: query,
      results: [
        for (final page in found.results) parseProviderPage(page, language),
      ],
      corrected: found.isCorrected ? found.shownQuery : null,
    );
  }
}
