import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cover_view.dart';
import '../../app/providers.dart';
import '../../components/cover_image.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/peek_row.dart';
import '../../components/pressable.dart';
import '../../components/skeleton.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../icons/icon_def.dart';
import '../../library/count_format.dart';
import 'detail_block.dart';
import 'overview_info.dart';

/// What MAL says about the title: the synopsis and the background in a
/// column of readable width, with the information and the title's other
/// names beside it when the window is wide. The synopsis shows whole while
/// it ends beside the information block; past it, it is cut there with More.
class OverviewPart extends StatefulWidget {
  const OverviewPart({
    super.key,
    required this.details,
    required this.hidden,
    required this.fetching,
  });

  final TitleDetails details;

  /// Streamer mode on an adult title: the synopsis is not shown.
  final bool hidden;

  /// The full details are on their way, so a missing part may still come.
  final bool fetching;

  static const _infoWidth = Tokens.space5 * 14;

  // The text may shrink to this before the info column drops below it.
  static const _minTextWidth = Tokens.space5 * 15;

  @override
  State<OverviewPart> createState() => _OverviewPartState();
}

class _OverviewPartState extends State<OverviewPart> {
  final _infoKey = GlobalKey();

  // the information block's height once laid out; null until then, and when
  // the window is narrow and it sits under the text instead
  double? _infoHeight;

  // the heading over the synopsis and the gap under it, and the More line
  // with the gap over it, which both take room beside the information block
  double _around(TextScaler scaler) =>
      2 * scaler.scale(Tokens.text2) + Tokens.space3 + Tokens.space2;

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _infoKey.currentContext?.size?.height;
      if (height != _infoHeight) setState(() => _infoHeight = height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final hidden = widget.hidden;
    final fetching = widget.fetching;
    final names = [?details.otherName, ...details.otherNames];
    final synopsis = details.synopsis;
    final background = details.background;
    final scaler = MediaQuery.textScalerOf(context);
    final lineHeight = scaler.scale(Tokens.text2) * Tokens.lineHeightWrapped;
    final infoHeight = _infoHeight;
    // as many lines as end beside the information block, never under four
    final lines = infoHeight == null
        ? _Clamped.fewest
        : ((infoHeight - _around(scaler)) / lineHeight).floor().clamp(
            _Clamped.fewest,
            1 << 20,
          );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hidden)
          DetailBlock(
            title: 'Synopsis',
            child: Text(
              'Hidden in Streamer mode',
              style: AppText.paragraph(Tokens.inkMuted),
            ),
          )
        else if (synopsis != null)
          DetailBlock(
            title: 'Synopsis',
            child: _Clamped(synopsis, lines: lines),
          )
        else if (fetching)
          const DetailBlock(
            title: 'Synopsis',
            child: SkeletonLines(title: 1, line: 0.7),
          ),
        if (background != null)
          DetailBlock(
            title: 'Background',
            child: Text(background, style: AppText.paragraph(Tokens.ink)),
          ),
      ],
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: _infoKey,
          child: DetailBlock(
            title: 'Information',
            child: OverviewInfo(details),
          ),
        ),
        if (names.isNotEmpty)
          DetailBlock(
            title: 'Other names',
            child: Text(
              names.join('\n'),
              style: AppText.paragraph(Tokens.inkSoft),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >=
            OverviewPart._minTextWidth +
                Tokens.space5 +
                OverviewPart._infoWidth;
        if (wide) {
          _measure();
        } else if (_infoHeight != null) {
          // under the text the block is no measure for it
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _infoHeight = null);
          });
        }
        if (!wide) {
          return _Readable(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, info],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Readable(child: text)),
            const SizedBox(width: Tokens.space5),
            SizedBox(width: OverviewPart._infoWidth, child: info),
          ],
        );
      },
    );
  }
}

/// Running text cut to [lines], with More to open the rest and Less to cut
/// it again. Text that fits shows whole, with neither.
class _Clamped extends StatefulWidget {
  const _Clamped(this.text, {required this.lines});

  final String text;
  final int lines;

  static const fewest = 4;

  @override
  State<_Clamped> createState() => _ClampedState();
}

class _ClampedState extends State<_Clamped> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final style = AppText.paragraph(Tokens.ink);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.lines,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final cut = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: cut && !_open ? widget.lines : null,
              overflow: cut && !_open ? TextOverflow.ellipsis : null,
            ),
            if (cut) ...[
              const SizedBox(height: Tokens.space2),
              Pressable(
                label: _open ? 'Show less' : 'Show the whole synopsis',
                onPressed: () => setState(() => _open = !_open),
                builder: (context, state) => Text(
                  _open ? 'Less' : 'More',
                  style: AppText.label(
                    state.hovered || state.focused ? Tokens.ink : Tokens.amber,
                    bold: true,
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

/// Keeps a column of text to a width that reads comfortably.
class _Readable extends StatelessWidget {
  const _Readable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Tokens.detailTextWidth),
      child: child,
    ),
  );
}

/// MAL's numbers for the title: the score and how many gave it, the members,
/// and a bar of how the members' lists split, with each count beside its
/// name.
class StatsPart extends StatelessWidget {
  const StatsPart({super.key, required this.details});

  final TitleDetails details;

  static bool hasAny(TitleDetails details) =>
      details.score != null ||
      details.listUsers != null ||
      details.listCounts != null;

  @override
  Widget build(BuildContext context) {
    final counts = details.listCounts;
    final score = details.score;
    final scoredBy = details.scoredBy;
    final members = details.listUsers;
    final lines = counts == null
        ? const <(String, int, Color)>[]
        : [
            ('Watching', counts.watching, Tokens.mint),
            ('Completed', counts.completed, Tokens.inkSoft),
            ('On hold', counts.onHold, Tokens.amber),
            ('Dropped', counts.dropped, Tokens.red),
            ('Plan to watch', counts.planned, Tokens.line),
          ];
    final total = lines.fold(0, (sum, line) => sum + line.$2);
    return DetailBlock(
      title: 'Stats',
      child: _Readable(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Tokens.space5,
              runSpacing: Tokens.space2,
              children: [
                if (score != null)
                  Text(
                    'Score ${score.toStringAsFixed(2)}'
                    '${scoredBy == null ? '' : ', given by ${formatCount(scoredBy)}'}',
                    style: AppText.label(Tokens.ink),
                  ),
                if (members != null)
                  Text(
                    '${formatCount(members)} members',
                    style: AppText.label(Tokens.inkSoft),
                  ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: Tokens.space4),
              SizedBox(
                height: Tokens.space3,
                child: Row(
                  children: [
                    for (final (_, count, color) in lines)
                      if (count > 0)
                        Expanded(
                          flex: count,
                          child: ColoredBox(color: color),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: Tokens.space3),
              for (final (label, count, color) in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: Tokens.space3,
                        child: ColoredBox(color: color),
                      ),
                      const SizedBox(width: Tokens.space2),
                      Expanded(
                        child: Text(label, style: AppText.label(Tokens.ink)),
                      ),
                      Text(
                        '${formatCount(count)}  ${(count * 100 / total).round()}%',
                        style: AppText.tally(Tokens.inkSoft),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The opening and ending themes, numbered, as MAL writes them.
class MusicPart extends StatelessWidget {
  const MusicPart({super.key, required this.details});

  final TitleDetails details;

  static bool hasAny(TitleDetails details) =>
      details.openings.isNotEmpty || details.endings.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    Widget song(String tag, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Tokens.space5 * 2,
            child: Text(tag, style: AppText.count(Tokens.inkMuted)),
          ),
          Expanded(child: Text(text, style: AppText.paragraph(Tokens.ink))),
        ],
      ),
    );
    return DetailBlock(
      title: 'Music',
      child: _Readable(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, text) in details.openings.indexed)
              song('OP ${i + 1}', text),
            for (final (i, text) in details.endings.indexed)
              song('ED ${i + 1}', text),
          ],
        ),
      ),
    );
  }
}

/// MAL's trailers and promotional videos, each opening in the browser.
class TrailersPart extends ConsumerWidget {
  const TrailersPart({super.key, required this.videos});

  final List<TitleVideo> videos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailBlock(
      title: 'Trailers',
      child: _Readable(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final video in videos)
              _LinkRow(
                icon: AppIcons.play,
                text: video.title,
                onPressed: () =>
                    ref.read(servicesProvider).openBrowser(video.url),
              ),
            const SizedBox(height: Tokens.space2),
            Text(
              'Opens in your browser',
              style: AppText.caption(Tokens.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line that opens something: its icon, then its text.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.text,
    required this.onPressed,
    this.note,
  });

  final IconDef icon;
  final String text;
  final String? note;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: text,
      onPressed: onPressed,
      builder: (context, state) => HoverMark(
        on: state.hovered || state.focused,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Tokens.space2),
          child: Row(
            children: [
              AppIcon(
                icon,
                size: Tokens.iconSize,
                color: state.hovered ? Tokens.amber : Tokens.inkMuted,
              ),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: OneLineText(text, style: AppText.label(Tokens.ink)),
              ),
              if (note != null) ...[
                const SizedBox(width: Tokens.space3),
                Text(note!, style: AppText.caption(Tokens.inkSoft)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// MAL's extra pictures of the title in a peeking row.
class PicturesPart extends StatelessWidget {
  const PicturesPart({super.key, required this.malId, required this.pictures});

  final int malId;
  final List<String> pictures;

  @override
  Widget build(BuildContext context) {
    return DetailBlock(
      title: 'Pictures',
      child: PeekRow(
        count: pictures.length,
        minItemWidth: Tokens.gridCardMinWidth,
        arrowTop: (width) =>
            (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
        itemBuilder: (context, i, width) =>
            _Picture(malId: malId, url: pictures[i], width: width),
      ),
    );
  }
}

class _Picture extends ConsumerWidget {
  const _Picture({required this.malId, required this.url, required this.width});

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

/// What MAL's users recommend after this title, as covers in a peeking row.
/// A click opens that title's page.
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
    return DetailBlock(
      title: 'Recommendations',
      child: PeekRow(
        count: titles.length,
        minItemWidth: Tokens.peekItemMinWidth,
        arrowTop: (width) =>
            (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
        itemBuilder: (context, i, width) {
          final title = titles[i];
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
                  if (title.note != null) ...[
                    const SizedBox(height: Tokens.space1),
                    OneLineText(
                      title.note!,
                      style: AppText.label(Tokens.inkSoft),
                    ),
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

/// The manga the title comes from or leads to, each opening its MAL page in
/// the browser.
class MangaPart extends ConsumerWidget {
  const MangaPart({super.key, required this.titles});

  final List<LinkedTitle> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailBlock(
      title: 'Manga',
      child: _Readable(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final title in titles)
              _LinkRow(
                icon: AppIcons.library,
                text: title.name,
                note: title.note,
                onPressed: () => ref
                    .read(servicesProvider)
                    .openBrowser(
                      Uri.https('myanimelist.net', '/manga/${title.malId}'),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
