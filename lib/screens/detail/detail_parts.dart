import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../components/link_row.dart';
import '../../components/pressable.dart';
import '../../components/skeleton.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/theme_song.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../icons/score_star.dart';
import '../../library/count_format.dart';
import 'detail_block.dart';

/// What MAL says about the title: the synopsis and the background in a
/// column of readable width, and beside it when the window is wide a box of
/// facts in named groups with the title's other names. The synopsis shows
/// whole while it ends beside the facts; past them, it is cut with More.
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

  static const _factsWidth = Tokens.space5 * 14;

  // The text may shrink to this before the facts drop below it.
  static const _minTextWidth = Tokens.space5 * 15;

  static const _gap = Tokens.space5 + Tokens.space4;

  @override
  State<OverviewPart> createState() => _OverviewPartState();
}

class _OverviewPartState extends State<OverviewPart> {
  final _factsKey = GlobalKey();

  // the facts box's height once laid out; null until then, and when the
  // window is narrow and it sits under the text instead
  double? _factsHeight;

  // the More line and the gap over it take room beside the facts too
  double _around(TextScaler scaler) =>
      scaler.scale(Tokens.text2) + Tokens.space2;

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _factsKey.currentContext?.size?.height;
      if (height != _factsHeight) setState(() => _factsHeight = height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final synopsis = details.synopsis;
    final background = details.background;
    final scaler = MediaQuery.textScalerOf(context);
    final lineHeight = scaler.scale(Tokens.text2) * Tokens.lineHeightWrapped;
    final factsHeight = _factsHeight;
    // as many lines as end beside the facts, never under four
    final lines = factsHeight == null
        ? _Clamped.fewest
        : ((factsHeight - _around(scaler)) / lineHeight).floor().clamp(
            _Clamped.fewest,
            1 << 20,
          );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hidden)
          Text(
            'Synopsis hidden in Streamer mode',
            style: AppText.paragraph(Tokens.inkMuted),
          )
        else if (synopsis != null)
          _Clamped(synopsis, lines: lines)
        else if (widget.fetching)
          const SkeletonLines(title: 1, line: 0.7),
        if (background != null) ...[
          const SizedBox(height: Tokens.space5 + Tokens.space2),
          DetailBlock(
            title: 'Background',
            last: true,
            child: Text(background, style: AppText.paragraph(Tokens.inkMuted)),
          ),
        ],
      ],
    );
    final facts = KeyedSubtree(key: _factsKey, child: _Facts(details));
    return DetailSection(
      title: 'Overview',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >=
              OverviewPart._minTextWidth +
                  OverviewPart._gap +
                  OverviewPart._factsWidth;
          if (wide) {
            _measure();
          } else if (_factsHeight != null) {
            // under the text the box is no measure for it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _factsHeight = null);
            });
          }
          if (!wide) {
            return _Readable(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text,
                  const SizedBox(height: Tokens.space5),
                  facts,
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Readable(child: text)),
              const SizedBox(width: OverviewPart._gap),
              SizedBox(width: OverviewPart._factsWidth, child: facts),
            ],
          );
        },
      ),
    );
  }
}

/// The title's facts in a quiet box, as a wiki's infobox groups them: when
/// it airs, where it comes from, and what else it is called.
class _Facts extends StatelessWidget {
  const _Facts(this.details);

  final TitleDetails details;

  static const _labelWidth = Tokens.space5 * 4;

  @override
  Widget build(BuildContext context) {
    final names = details.otherNames;
    final groups = <(String, Widget)>[
      for (final (name, rows) in infoGroups(details))
        (
          name,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _labelWidth,
                        child: Text(
                          label,
                          style: AppText.paragraph(Tokens.inkMuted),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          value,
                          style: AppText.paragraph(Tokens.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      if (names.isNotEmpty)
        (
          'Also known as',
          Text(names.join('\n'), style: AppText.paragraph(Tokens.inkSoft)),
        ),
    ];
    if (groups.isEmpty) return const SizedBox.shrink();
    return ColoredBox(
      color: Tokens.raised,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space5,
          vertical: Tokens.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (name, child)) in groups.indexed) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Tokens.space4),
                  child: ColoredBox(
                    color: Tokens.surface,
                    child: SizedBox(height: 1),
                  ),
                ),
              DetailHeading(name),
              const SizedBox(height: Tokens.space2),
              child,
            ],
          ],
        ),
      ),
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
    final style = AppText.paragraph(Tokens.inkSoft);
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
                    state.hovered || state.focused ? Tokens.ink : Tokens.pop,
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

/// MAL's numbers behind the top's facts: how many scored it and how many
/// have it on a list, then how those lists split, each status a chip with
/// its count over one thin bar of the whole.
class StatsPart extends StatelessWidget {
  const StatsPart({super.key, required this.details});

  final TitleDetails details;

  static bool hasAny(TitleDetails details) =>
      details.scoredBy != null ||
      details.listUsers != null ||
      details.listCounts != null;

  @override
  Widget build(BuildContext context) {
    final counts = details.listCounts;
    final scoredBy = details.scoredBy;
    final members = details.listUsers;
    final statuses = counts == null
        ? const <(String, int, Color)>[]
        : [
            ('Watching', counts.watching, Tokens.ink),
            ('Completed', counts.completed, Tokens.inkSoft),
            ('On hold', counts.onHold, Tokens.pop),
            ('Dropped', counts.dropped, Tokens.red),
            ('Plan to watch', counts.planned, Tokens.line),
          ];
    final total = statuses.fold(0, (sum, line) => sum + line.$2);
    return DetailSection(
      title: 'Stats',
      aside: const SectionNote('On MyAnimeList'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Tokens.space5 + Tokens.space4,
            runSpacing: Tokens.space4,
            children: [
              if (scoredBy != null)
                _Figure(
                  icon: const ScoreStar(
                    size: Tokens.iconSize,
                    color: Tokens.inkMuted,
                  ),
                  value: formatCount(scoredBy),
                  label: 'scored it',
                ),
              if (members != null)
                _Figure(
                  icon: const AppIcon(
                    AppIcons.people,
                    size: Tokens.iconSize,
                    color: Tokens.inkMuted,
                  ),
                  value: formatCount(members),
                  label: 'have it on a list',
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: Tokens.space5),
            _StatusChips(statuses: statuses, total: total),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.icon, required this.value, required this.label});

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: Tokens.space3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppText.tally(
                Tokens.ink,
                size: Tokens.text3,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Tokens.space1),
            Text(label, style: AppText.caption(Tokens.inkMuted)),
          ],
        ),
      ],
    );
  }
}

/// One chip per list status, as many to a row as fit, over a bar that
/// splits the whole by the same colors.
class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.statuses, required this.total});

  final List<(String, int, Color)> statuses;
  final int total;

  static const _gap = Tokens.space1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth;
        final perRow = ((room + _gap) / (Tokens.peekItemMinWidth + _gap))
            .floor()
            .clamp(1, statuses.length);
        final width = (room - (perRow - 1) * _gap) / perRow;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final (label, count, color) in statuses)
                  SizedBox(
                    width: width,
                    child: _Chip(
                      label: label,
                      count: count,
                      share: count / total,
                      color: color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: _gap),
            SizedBox(
              height: Tokens.space1,
              child: Row(
                children: [
                  for (final (_, count, color) in statuses)
                    if (count > 0)
                      Expanded(
                        flex: count,
                        child: ColoredBox(color: color),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.share,
    required this.color,
  });

  final String label;
  final int count;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = share * 100;
    // a status too small to round to 1% still shows it is there
    final shown = percent > 0 && percent < 1 ? '<1%' : '${percent.round()}%';
    return Container(
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: Tokens.raised,
        border: Border(
          top: BorderSide(color: color, width: Tokens.hoverEdge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption(Tokens.inkMuted)),
          const SizedBox(height: Tokens.space2),
          Text(
            formatCount(count),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: AppText.tally(Tokens.inkSoft)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Tokens.space1),
          Text(shown, style: AppText.caption(Tokens.inkMuted)),
        ],
      ),
    );
  }
}

/// The opening and ending songs as two track lists, side by side when there
/// is room. A song opens a YouTube search for it in the browser.
class MusicPart extends StatelessWidget {
  const MusicPart({super.key, required this.details});

  final TitleDetails details;

  static bool hasAny(TitleDetails details) =>
      details.openings.isNotEmpty || details.endings.isNotEmpty;

  static const _columnGap = Tokens.space5 * 2;

  @override
  Widget build(BuildContext context) {
    final openings = details.openings;
    final endings = details.endings;
    final count = openings.length + endings.length;
    final lists = [
      if (openings.isNotEmpty) ('Openings', 'OP', openings),
      if (endings.isNotEmpty) ('Endings', 'ED', endings),
    ];
    Widget list((String, String, List<ThemeSong>) item, {required bool last}) {
      final (title, tag, songs) = item;
      return DetailBlock(
        title: title,
        last: last,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final song in songs) _SongRow(tag: tag, song: song)],
        ),
      );
    }

    return DetailSection(
      title: 'Music',
      count: count == 1 ? '1 song' : '$count songs',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoUp =
              lists.length == 2 &&
              constraints.maxWidth >= Tokens.detailTextWidth + _columnGap;
          if (twoUp) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: list(lists[0], last: true)),
                const SizedBox(width: _columnGap),
                Expanded(child: list(lists[1], last: true)),
              ],
            );
          }
          return Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Tokens.detailTextWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in lists.indexed)
                    list(item, last: i == lists.length - 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One song in a track list: its number, the name bright with the Japanese
/// name quiet beside it, the artist under it, and where it plays at the
/// right. Under the pointer a search mark shows what a click does.
class _SongRow extends ConsumerWidget {
  const _SongRow({required this.tag, required this.song});

  final String tag;
  final ThemeSong song;

  static const _numberWidth = Tokens.space5 * 2;
  static const _episodesWidth = Tokens.space5 * 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final native = song.nativeName;
    final artist = song.artist;
    final episodes = song.episodes;
    final query = [song.name, ?artist].join(' ');
    return LinkRow(
      label: 'Find ${song.name} on YouTube',
      onPressed: () => ref
          .read(servicesProvider)
          .openBrowser(
            Uri.https('www.youtube.com', '/results', {'search_query': query}),
          ),
      children: (lit) => [
        SizedBox(
          width: _numberWidth,
          child: Text(
            '$tag ${song.number}',
            style: AppText.count(Tokens.inkMuted),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: song.name,
                      style: AppText.label(Tokens.ink, bold: true),
                    ),
                    if (native != null)
                      TextSpan(
                        text: '  $native',
                        style: AppText.caption(Tokens.inkMuted),
                      ),
                  ],
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              if (artist != null) ...[
                const SizedBox(height: Tokens.space1),
                Text(
                  artist,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption(Tokens.inkSoft),
                ),
              ],
            ],
          ),
        ),
        if (episodes != null) ...[
          const SizedBox(width: Tokens.space3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _episodesWidth),
            child: Text(
              episodes,
              textAlign: TextAlign.right,
              style: AppText.figure(Tokens.inkMuted)
                  .copyWith(height: Tokens.lineHeightWrapped),
            ),
          ),
        ],
        const SizedBox(width: Tokens.space2),
        Opacity(
          opacity: lit ? 1 : 0,
          child: const AppIcon(
            AppIcons.search,
            size: Tokens.iconSize,
            color: Tokens.pop,
          ),
        ),
      ],
    );
  }
}
