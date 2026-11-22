import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../components/picture_fade.dart';
import '../../components/picture_crop.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';

/// The ground of the Detail top: a picture of the title under an even veil
/// that falls into the chassis at the foot. The picture is one of MAL's
/// extra pictures when the title has a fit one, else the large cover; the
/// cover shows first and the other fades over it once all the pictures are
/// in, so it changes at most once.
class HeroGround extends ConsumerWidget {
  const HeroGround({super.key, required this.malId, this.details});

  final int malId;
  final TitleDetails? details;

  /// How tall the plain chassis is at the foot, under the fade.
  static const solidFoot = Tokens.space3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = _alternate(ref) ?? _cover(ref);
    // the veil is cached with the picture, so a layer drawn rounded out to
    // whole pixels has veil in its fringe too, never bare picture. The foot
    // is plain chassis for [solidFoot], so the picture can shift a pixel or
    // two against the jump bar while scrolling and the seam is still chassis
    // against chassis
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            bottom: solidFoot,
            child: PictureFade(look: look),
          ),
          Positioned.fill(
            bottom: solidFoot,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Tokens.ground.withValues(alpha: Tokens.heroVeil),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: solidFoot + 1,
            child: ColoredBox(color: Tokens.chassisTop),
          ),
          Positioned.fill(
            bottom: solidFoot,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Tokens.chassisTop.withValues(alpha: 0),
                    Tokens.chassisTop,
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PictureLook? _cover(WidgetRef ref) {
    final file = ref.watch(largeCoverProvider(malId)).value;
    if (file == null) return null;
    return ref.watch(pictureLookProvider(file.path)).value;
  }

  PictureLook? _alternate(WidgetRef ref) {
    final details = this.details;
    if (details == null) return null;
    final cover = details.coverUrl;
    final urls = [
      for (final url in details.pictures)
        if (cover == null || !sameMalPicture(url, cover)) url,
    ];
    if (urls.isEmpty) return null;
    final looks = <PictureLook>[];
    var settled = true;
    for (final url in urls) {
      final file = ref.watch(titlePictureProvider(malId, url));
      if (file.isLoading) {
        settled = false;
        continue;
      }
      final path = file.value?.path;
      if (path == null) continue;
      final look = ref.watch(pictureLookProvider(path));
      if (look.isLoading) {
        settled = false;
      } else if (look.value case final value?) {
        looks.add(value);
      }
    }
    // pick only once every picture is in, so the ground changes once
    return settled ? chooseAlternate(looks) : null;
  }
}
