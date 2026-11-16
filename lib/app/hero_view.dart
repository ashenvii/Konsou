import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../covers/cover_size.dart';
import '../design/tokens.dart';
import 'frosted_picture.dart';
import 'providers.dart';

/// The wide picture behind the top of the Detail page, frosted. It is one of
/// MAL's extra pictures, cropped to the band; until that is in, or when the
/// title has none, the large cover is cropped to the band instead.
class HeroView extends ConsumerWidget {
  const HeroView({super.key, required this.malId, required this.width});

  final int malId;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroFileProvider(malId)).value;
    final file =
        hero ?? ref.watch(coverFileProvider(malId, CoverSize.large)).value;
    if (file == null) return SizedBox(width: width, height: Tokens.heroHeight);
    return FrostedPicture(
      file: file,
      width: width,
      height: Tokens.heroHeight,
      alignment: const Alignment(0, -0.3),
    );
  }
}
