import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/cover_image.dart';
import '../covers/cover_size.dart';
import 'providers.dart';

/// A title's cover by MAL id, read from disk or fetched in [lane].
class CoverView extends ConsumerWidget {
  const CoverView({
    super.key,
    required this.malId,
    required this.width,
    this.loading = false,
    this.pictureUrl,
    this.lane = Lane.screen,
  });

  final int? malId;
  final double width;

  /// The cover's address for a title with no details saved, such as a
  /// recommendation.
  final String? pictureUrl;

  final bool loading;

  /// [Lane.page] for covers of the open page and the titles around it.
  final Lane lane;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = malId;
    if (id == null) return CoverImage(width: width);
    final size = chooseCoverSize(
      drawnWidth: width,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    // a kept cover draws at once, with no skeleton and no wait
    final kept = ref.watch(
      keptCoversProvider.select((covers) => covers.value?[(id, size)]),
    );
    if (kept != null) return CoverImage(width: width, file: kept);
    final listRead = ref.watch(
      keptCoversProvider.select((covers) => covers.hasValue),
    );
    // the list of kept covers is still being read: a moment, so no skeleton
    if (!listRead) return CoverImage(width: width, loading: loading);
    if (loading) {
      // without details the cover lookup came back empty, so look again later
      ref.listen(detailOnScreenProvider(id, lane: lane), (_, state) {
        if (state is AsyncData) {
          ref.invalidate(
            coverFileProvider(id, size, pictureUrl: pictureUrl, lane: lane),
          );
        }
      });
    }
    final cover = ref.watch(
      coverFileProvider(id, size, pictureUrl: pictureUrl, lane: lane),
    );
    final file = cover.value;
    // a cover saved after this one was drawn blank: read it again
    ref.listen(coverSavedProvider, (_, saved) {
      if (file == null && saved.asData?.value == id) {
        ref.invalidate(
          coverFileProvider(id, size, pictureUrl: pictureUrl, lane: lane),
        );
      }
    });
    return CoverImage(
      width: width,
      file: file,
      // still reading or fetching it, or the details are not in yet
      loading: loading || cover.isLoading,
    );
  }
}
