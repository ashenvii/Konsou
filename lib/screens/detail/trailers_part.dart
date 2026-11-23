import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../components/cover_image.dart';
import '../../components/one_line_text.dart';
import '../../components/peek_row.dart';
import '../../components/pressable.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../library/count_format.dart';
import 'detail_section.dart';
import 'section_note.dart';

/// MAL's trailers and promotional videos as pictures in a peeking row, each
/// opening in the browser.
class TrailersPart extends StatelessWidget {
  const TrailersPart({super.key, required this.malId, required this.videos});

  final int malId;
  final List<TitleVideo> videos;

  static double pictureHeight(double width) => width * 9 / 16;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Trailers',
      count: formatCountOf(videos.length, 'video'),
      aside: const SectionNote('Opens in your browser'),
      child: PeekRow(
        count: videos.length,
        minItemWidth: Tokens.videoMinWidth,
        arrowTop: (width) => (pictureHeight(width) - Tokens.controlHeight) / 2,
        itemBuilder: (context, i, width) =>
            _VideoTile(malId: malId, video: videos[i], width: width),
      ),
    );
  }
}

/// A trailer: its picture with a play mark that turns pop under the
/// pointer, its name, and where it plays.
class _VideoTile extends ConsumerWidget {
  const _VideoTile({
    required this.malId,
    required this.video,
    required this.width,
  });

  final int malId;
  final TitleVideo video;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = video.thumbnail;
    final picture = thumbnail == null
        ? null
        : ref.watch(titlePictureProvider(malId, thumbnail));
    final host = video.url.host;
    final site = host.contains('youtu') ? 'YouTube' : host;
    return Pressable(
      label: 'Play ${video.title} in your browser',
      onPressed: () => ref.read(openLinkProvider)(video.url),
      builder: (context, state) {
        final lit = state.hovered || state.focused;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CoverImage(
                  width: width,
                  height: TrailersPart.pictureHeight(width),
                  file: picture?.value,
                  loading: picture?.isLoading ?? false,
                ),
                Positioned(
                  left: Tokens.space3,
                  bottom: Tokens.space3,
                  child: Container(
                    width: Tokens.controlHeight,
                    height: Tokens.controlHeight,
                    alignment: Alignment.center,
                    color: lit ? Tokens.pop : Tokens.ink,
                    child: const AppIcon(
                      AppIcons.play,
                      size: Tokens.iconSize,
                      color: Tokens.ground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.space2),
            OneLineText(
              video.title,
              style: AppText.label(Tokens.ink, bold: true),
            ),
            const SizedBox(height: Tokens.space1),
            Text(site, style: AppText.caption(Tokens.inkMuted)),
            const SizedBox(height: Tokens.space2),
          ],
        );
      },
    );
  }
}
