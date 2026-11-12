import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../covers/cover_size.dart';
import '../covers/cover_store.dart';
import '../mal/detail_request.dart';
import '../mal/request_gate.dart';
import 'services.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Services services(Ref ref) => throw UnimplementedError('override in main');

@Riverpod(keepAlive: true)
CoverStore? coverStore(Ref ref) => ref.watch(servicesProvider).coverStore;

@Riverpod(keepAlive: true)
Stream<int> coverSaved(Ref ref) => ref.watch(servicesProvider).coverSaved;

@Riverpod(keepAlive: true)
class KeptCovers extends _$KeptCovers {
  @override
  Future<Map<(int, CoverSize), File>> build() async {
    final store = ref.watch(coverStoreProvider);
    if (store == null) return {};
    ref.listen(coverSavedProvider, (_, saved) {
      final malId = saved.value;
      if (malId != null) _add(store, malId);
    });
    return store.readKept();
  }

  Future<void> _add(CoverStore store, int malId) async {
    for (final size in CoverSize.values) {
      final file = await store.keptFile(malId, size);
      final kept = state.value;
      if (file == null || kept == null) continue;
      state = AsyncData({...kept, (malId, size): file});
    }
  }
}

@riverpod
Future<File?> coverFile(Ref ref, int malId, CoverSize size) async {
  final store = ref.watch(coverStoreProvider);
  if (store == null) return null;
  // the fetch is dropped from the queue if the card is gone by its turn
  var gone = false;
  ref.onDispose(() => gone = true);
  final kept = await store.readCover(malId, size);
  if (kept != null) return kept;
  final outcome = await store.fetchCover(
    malId,
    size,
    lane: Lane.screen,
    wanted: () => !gone,
  );
  if (outcome == CoverOutcome.fetched || outcome == CoverOutcome.current) {
    return store.readCover(malId, size);
  }
  return null;
}

@riverpod
Future<void> detailOnScreen(Ref ref, int malId) async {
  final services = ref.watch(servicesProvider);
  final request = services.detailRequest;
  if (request == null) return;
  var gone = false;
  ref.onDispose(() => gone = true);
  final outcome = await request.fetch(
    malId,
    lane: Lane.screen,
    full: false,
    wanted: () => !gone,
  );
  if (outcome == FetchOutcome.fetched) services.notifyScreenDataChanged();
}
