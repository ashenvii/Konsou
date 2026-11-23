import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../components/link_row.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/theme_song.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../library/count_format.dart';
import 'detail_block.dart';
import 'detail_section.dart';
import 'readable_width.dart';

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
      count: formatCountOf(count, 'song'),
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
          return ReadableWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, item) in lists.indexed)
                  list(item, last: i == lists.length - 1),
              ],
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
      onPressed: () => ref.read(openLinkProvider)(
        Uri.https('www.youtube.com', '/results', {'search_query': query}),
      ),
      children: (lit) => [
        SizedBox(
          width: _numberWidth,
          child: Text(
            '$tag ${song.number}',
            style: AppText.tally(Tokens.inkMuted, size: Tokens.text1),
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
              style: AppText.tally(
                Tokens.inkMuted,
                size: Tokens.text1,
              ).copyWith(height: Tokens.lineHeightWrapped),
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
