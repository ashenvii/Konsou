import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../covers/cover_size.dart';
import '../components/picture_crop.dart';
import '../covers/cover_store.dart';
import '../mal/detail_request.dart';
import '../mal/request_gate.dart';
import 'services.dart';

export '../mal/request_gate.dart' show Lane;

part 'providers.g.dart';

/// The app's [Services]; main overrides it with the real ones.
@Riverpod(keepAlive: true)
Services services(Ref ref) => throw UnimplementedError('override in main');

/// Opens a link in the user's browser, for a screen's links out.
@riverpod
Future<void> Function(Uri url) openLink(Ref ref) =>
    ref.watch(servicesProvider).openBrowser;

/// The cover store, null when there is none.
@Riverpod(keepAlive: true)
CoverStore? coverStore(Ref ref) => ref.watch(servicesProvider).coverStore;

/// The MAL id of each cover as it is saved.
@Riverpod(keepAlive: true)
Stream<int> coverSaved(Ref ref) => ref.watch(servicesProvider).coverSaved;

/// The covers on disk by MAL id and size, growing as new ones are saved.
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

/// One cover file, read from disk or fetched in [lane].
@riverpod
Future<File?> coverFile(
  Ref ref,
  int malId,
  CoverSize size, {
  String? pictureUrl,
  Lane lane = Lane.screen,
}) async {
  final store = ref.watch(coverStoreProvider);
  if (store == null) return null;
  final kept = await store.readCover(malId, size);
  if (kept != null) return kept;
  final outcome = await store.fetchCover(
    malId,
    size,
    lane: lane,
    // the fetch is dropped from the queue if the card is gone by its turn
    wanted: () => ref.mounted,
    pictureUrl: pictureUrl,
  );
  if (outcome == CoverOutcome.fetched || outcome == CoverOutcome.current) {
    return store.readCover(malId, size);
  }
  return null;
}

/// One of MAL's extra pictures of a title, kept for the last few titles.
@riverpod
Future<File?> titlePicture(Ref ref, int malId, String url) async {
  final store = ref.watch(coverStoreProvider);
  if (store == null) return null;
  return store.pictureFile(malId, url, wanted: () => ref.mounted);
}

/// Fetches a title's short details while its row is on screen.
@riverpod
Future<void> detailOnScreen(
  Ref ref,
  int malId, {
  Lane lane = Lane.screen,
}) async {
  final services = ref.watch(servicesProvider);
  final request = services.detailRequest;
  if (request == null) return;
  final outcome = await request.fetch(
    malId,
    lane: lane,
    full: false,
    wanted: () => ref.mounted,
  );
  if (outcome == FetchOutcome.fetched) services.notifyScreenDataChanged();
}

/// The large cover of a title, kept or fetched.
@riverpod
Future<File?> largeCover(Ref ref, int malId) async {
  final kept = await ref.watch(keptCoversProvider.future);
  return kept[(malId, CoverSize.large)] ??
      ref.watch(
        coverFileProvider(malId, CoverSize.large, lane: Lane.page).future,
      );
}

/// A picture file's size and detail per row, for cropping it to a box.
@riverpod
Future<PictureLook?> pictureLook(Ref ref, String path) =>
    PictureLook.read(File(path));
