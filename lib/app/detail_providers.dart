import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/databases.dart';
import '../detail/provider_page.dart';
import '../detail/streamer_mode.dart';
import '../detail/title_details.dart';
import '../detail/title_entry.dart';
import '../detail/watch_order.dart';
import '../library/load_library.dart';
import '../mal/detail_request.dart';
import '../mal/request_gate.dart';
import 'providers.dart';

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
  var _left = false;

  @override
  Future<DetailPageData> build(int malId, {String? entryId}) async {
    final services = ref.watch(servicesProvider);
    _left = false;
    ref.onDispose(() => _left = true);
    _reloadOnEdit(ref, services.databases, _reload);
    final saved = await _read();
    final wantsFetch =
        services.detailRequest != null &&
        (saved.details?.needsFetch(DateTime.now()) ?? true);
    if (!wantsFetch) return saved;
    // after this build's value is in, so the fetch's answer is not overwritten
    Future(_fetch);
    return saved.withFetch(DetailFetch.running);
  }

  Future<void> retry() async {
    final shown = state.value;
    if (shown == null || shown.fetch == DetailFetch.running) return;
    state = AsyncData(shown.withFetch(DetailFetch.running));
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_left) return;
    final services = ref.read(servicesProvider);
    final outcome = await services.detailRequest!.fetch(
      malId,
      lane: Lane.screen,
      full: true,
      wanted: () => !_left,
    );
    if (_left) return;
    if (outcome == FetchOutcome.fetched) services.notifyScreenDataChanged();
    final saved = await _read();
    if (_left) return;
    state = AsyncData(
      saved.withFetch(switch (outcome) {
        FetchOutcome.fetched => DetailFetch.idle,
        FetchOutcome.gone => DetailFetch.gone,
        FetchOutcome.offline => DetailFetch.offline,
        FetchOutcome.failed => DetailFetch.failed,
      }),
    );
  }

  Future<void> _reload() async {
    final saved = await _read();
    if (_left) return;
    state = AsyncData(saved.withFetch(state.value?.fetch ?? DetailFetch.idle));
  }

  Future<DetailPageData> _read() async {
    final databases = ref.read(servicesProvider).databases;
    final language = await readTitleLanguage(databases.record);
    final details = await readTitleDetails(databases, malId, language);
    return DetailPageData(
      details: details,
      entry: await readEntryOnPage(databases, malId, preferred: entryId),
      isHidden: isHiddenInStreamerMode(
        streamerMode: await readStreamerMode(databases.record),
        nsfw: details?.nsfw,
      ),
    );
  }
}

@riverpod
Future<WatchOrder> watchOrder(Ref ref, int malId) async {
  final services = ref.watch(servicesProvider);
  final databases = services.databases;
  _reloadOnEdit(ref, databases, ref.invalidateSelf);
  // a title fetched while the page is open may bring new relations
  final listener = services.screenDataChanged.listen(
    (_) => ref.invalidateSelf(),
  );
  ref.onDispose(listener.cancel);
  return loadWatchOrder(
    databases,
    malId,
    await readTitleLanguage(databases.record),
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
  return NotLinkedPage(
    entry: await readEntry(databases, entryId),
    suggestions: await readSuggestions(
      databases,
      entryId,
      await readTitleLanguage(databases.record),
    ),
  );
}
