import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/cover_image.dart';
import '../covers/cover_size.dart';
import 'providers.dart';

/// The cover of a MAL title at the smallest file that is sharp at [width] on
/// this screen. A null [malId] (an entry not linked yet) is the blank cover.
class CoverView extends ConsumerWidget {
  const CoverView({super.key, required this.malId, required this.width});

  final int? malId;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = malId;
    if (id == null) return CoverImage(width: width);
    final size = chooseCoverSize(
      drawnWidth: width,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    final file = ref.watch(coverFileProvider(id, size)).value;
    // a cover saved after this one was drawn blank: read it again
    ref.listen(coverSavedProvider, (_, saved) {
      if (file == null && saved.asData?.value == id) {
        ref.invalidate(coverFileProvider(id, size));
      }
    });
    return CoverImage(width: width, file: file);
  }
}
