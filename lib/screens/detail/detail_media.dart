import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cover_view.dart';
import '../../app/providers.dart';
import '../../components/cover_image.dart';
import '../../components/fading_portal.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/peek_row.dart';
import '../../components/picture_overlay.dart';
import '../../components/link_row.dart';
import '../../components/pressable.dart';
import '../../components/solid_icon_button.dart';
import '../../components/tag.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import 'detail_block.dart';

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
      count: videos.length == 1 ? '1 video' : '${videos.length} videos',
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

/// A trailer: its picture with a play mark that turns cyan under the
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
      onPressed: () => ref.read(servicesProvider).openBrowser(video.url),
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

/// MAL's extra pictures of the title in a peeking row. A click opens one full
/// size, with arrows and the arrow keys to move through the rest.
class PicturesPart extends StatefulWidget {
  const PicturesPart({super.key, required this.malId, required this.pictures});

  final int malId;
  final List<String> pictures;

  @override
  State<PicturesPart> createState() => _PicturesPartState();
}

class _PicturesPartState extends State<PicturesPart>
    with FadingPortalOwner<PicturesPart> {
  var _open = 0;

  @override
  Widget build(BuildContext context) {
    final pictures = widget.pictures;
    return FadingPortal(
      controller: portal,
      visible: portalOpen,
      overlay: (context) => PictureViewer(
        malId: widget.malId,
        pictures: pictures,
        start: _open,
        onClose: closePortal,
      ),
      child: DetailSection(
        title: 'Pictures',
        count: pictures.length == 1
            ? '1 picture'
            : '${pictures.length} pictures',
        child: PeekRow(
          count: pictures.length,
          minItemWidth: Tokens.gridCardMinWidth,
          arrowTop: (width) =>
              (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
          itemBuilder: (context, i, width) => Pressable(
            label: 'Open picture ${i + 1} full size',
            onPressed: () => openPortal(() => _open = i),
            builder: (context, state) => Stack(
              children: [
                _Picture(malId: widget.malId, url: pictures[i], width: width),
                if (state.hovered || state.focused)
                  Positioned(
                    top: Tokens.space2,
                    right: Tokens.space2,
                    child: Container(
                      padding: const EdgeInsets.all(Tokens.space1),
                      color: Tokens.ground.withValues(alpha: 0.72),
                      child: const AppIcon(
                        AppIcons.expand,
                        size: Tokens.iconSize,
                        color: Tokens.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Picture extends ConsumerWidget {
  const _Picture({
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

/// The title's pictures full size, one at a time, from [start]: arrows at
/// the sides and the arrow keys move through them, the count shows above.
class PictureViewer extends StatefulWidget {
  const PictureViewer({
    super.key,
    required this.malId,
    required this.pictures,
    required this.start,
    required this.onClose,
  });

  final int malId;
  final List<String> pictures;
  final int start;
  final VoidCallback onClose;

  @override
  State<PictureViewer> createState() => _PictureViewerState();
}

class _PictureViewerState extends State<PictureViewer> {
  late var _index = widget.start;

  int get _count => widget.pictures.length;

  void _step(int by) => setState(() => _index = (_index + by) % _count);

  KeyEventResult _key(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _step(_count - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final many = _count > 1;
    return PictureOverlay(
      onClose: widget.onClose,
      onKey: _key,
      builder: (context, room) {
        const side = Tokens.controlHeight + Tokens.space4;
        const top = Tokens.text1 + Tokens.space4;
        final width = math.min(
          room.maxWidth - (many ? 2 * side : 0),
          (room.maxHeight - top) / CoverImage.heightFor(1),
        );
        return Stack(
          children: [
            Positioned.fill(
              top: top,
              child: Center(
                child: _Picture(
                  key: ValueKey(_index),
                  malId: widget.malId,
                  url: widget.pictures[_index],
                  width: width,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text(
                '${_index + 1} / $_count',
                textAlign: TextAlign.center,
                style: AppText.figure(Tokens.inkSoft),
              ),
            ),
            if (many) ...[
              Positioned(
                left: 0,
                top: top,
                bottom: 0,
                child: Center(
                  child: SolidIconButton(
                    icon: AppIcons.chevronLeft,
                    label: 'Earlier picture',
                    onPressed: () => _step(_count - 1),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: top,
                bottom: 0,
                child: Center(
                  child: SolidIconButton(
                    icon: AppIcons.chevronRight,
                    label: 'Later picture',
                    onPressed: () => _step(1),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// What MAL's users recommend after this title, as covers in a peeking row
/// with how many recommend each. A click opens that title's page.
class RecommendationsPart extends StatelessWidget {
  const RecommendationsPart({
    super.key,
    required this.titles,
    required this.onOpen,
  });

  final List<LinkedTitle> titles;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Recommendations',
      count: titles.length == 1 ? '1 title' : '${titles.length} titles',
      aside: const SectionNote('By MyAnimeList users'),
      child: PeekRow(
        count: titles.length,
        minItemWidth: Tokens.peekItemMinWidth,
        arrowTop: (width) =>
            (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
        itemBuilder: (context, i, width) {
          final title = titles[i];
          final note = title.note;
          return Pressable(
            label: 'Open ${title.name}',
            onPressed: () => onOpen(title.malId),
            builder: (context, state) => HoverMark(
              on: state.hovered || state.focused,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverView(
                    malId: title.malId,
                    width: width,
                    pictureUrl: title.pictureUrl,
                  ),
                  const SizedBox(height: Tokens.space2),
                  Text(
                    title.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      Tokens.ink,
                      bold: true,
                    ).copyWith(height: Tokens.lineHeightWrapped),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: Tokens.space1),
                    OneLineText(note, style: AppText.caption(Tokens.inkMuted)),
                  ],
                  const SizedBox(height: Tokens.space2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The manga the title comes from or leads to, each with how it relates and
/// opening its MAL page in the browser.
class MangaPart extends ConsumerWidget {
  const MangaPart({super.key, required this.titles});

  final List<LinkedTitle> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailSection(
      title: 'Manga',
      count: titles.length == 1 ? '1 title' : '${titles.length} titles',
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Tokens.detailTextWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final title in titles)
                _MangaRow(
                  title: title,
                  onPressed: () => ref
                      .read(servicesProvider)
                      .openBrowser(
                        Uri.https('myanimelist.net', '/manga/${title.malId}'),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MangaRow extends StatelessWidget {
  const _MangaRow({required this.title, required this.onPressed});

  final LinkedTitle title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final note = title.note;
    return LinkRow(
      label: 'Open ${title.name} on MyAnimeList',
      onPressed: onPressed,
      children: (lit) => [
        const AppIcon(
          AppIcons.library,
          size: Tokens.iconSize,
          color: Tokens.inkMuted,
        ),
        const SizedBox(width: Tokens.space3),
        Expanded(
          child: OneLineText(title.name, style: AppText.label(Tokens.ink)),
        ),
        if (note != null) ...[const SizedBox(width: Tokens.space3), Tag(note)],
        const SizedBox(width: Tokens.space3),
        AppIcon(
          AppIcons.external,
          size: Tokens.iconSize,
          color: lit ? Tokens.pop : Tokens.inkMuted,
        ),
      ],
    );
  }
}
