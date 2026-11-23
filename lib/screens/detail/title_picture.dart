import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../components/cover_image.dart';

/// One of MAL's extra pictures of a title.
class TitlePicture extends ConsumerWidget {
  const TitlePicture({
    super.key,
    required this.malId,
    required this.url,
    required this.width,
  });

  final int malId;
  final String url;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picture = ref.watch(titlePictureProvider(malId, url));
    return CoverImage(
      width: width,
      file: picture.value,
      loading: picture.isLoading,
    );
  }
}
