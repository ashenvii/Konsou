import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../covers/cover_size.dart';
import '../covers/cover_store.dart';
import '../mal/request_gate.dart';
import 'services.dart';

part 'providers.g.dart';

/// The background work and the databases, built once at launch. `main`
/// overrides it with the real thing; screens read the databases through it.
@Riverpod(keepAlive: true)
Services services(Ref ref) => throw UnimplementedError('override in main');

/// Null when no MAL client ID was built in, so no covers can be fetched.
@Riverpod(keepAlive: true)
CoverStore? coverStore(Ref ref) => ref.watch(servicesProvider).coverStore;

/// The MAL id of each cover as its file is saved, so a blank cover on screen
/// can swap in the picture.
@Riverpod(keepAlive: true)
Stream<int> coverSaved(Ref ref) => ref.watch(servicesProvider).coverSaved;

/// A cover's file: kept on the device, or fetched now ahead of the background
/// trickle. Null while the title has no details or no picture, or offline.
@riverpod
Future<File?> coverFile(Ref ref, int malId, CoverSize size) async {
  final store = ref.watch(coverStoreProvider);
  if (store == null) return null;
  final kept = await store.readCover(malId, size);
  if (kept != null) return kept;
  final outcome = await store.fetchCover(malId, size, lane: Lane.screen);
  if (outcome == CoverOutcome.fetched || outcome == CoverOutcome.current) {
    return store.readCover(malId, size);
  }
  return null;
}
