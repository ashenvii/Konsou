import 'package:flutter/widgets.dart';

import '../app/detail_providers.dart';
import '../components/card_foot.dart';
import '../components/details_panel.dart';
import '../components/key_cap.dart';
import '../components/mal_score_line.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/entry_status.dart';
import '../detail/title_details.dart';
import '../library/row_labels.dart';
import '../screens/library/card_details.dart';

const _types = [
  'tv',
  'movie',
  'ova',
  'ona',
  'special',
  'tv_special',
  'music',
  'cm',
  'pv',
];

/// The pieces every card shares, each in its states: the footer as it sits
/// in the well under a cover, the type tag, and the MAL score line.
class CardPiecesSection extends StatelessWidget {
  const CardPiecesSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _samples(Tokens.space4, [
        _foot(
          'Hovered, mixed tab',
          CardFoot(
            status: EntryStatus.watching,
            count: formatCardCount(onList: true, watched: 9, total: 28),
            showMark: true,
            showWord: true,
          ),
        ),
        _foot(
          'Mixed tab',
          CardFoot(
            status: EntryStatus.completed,
            count: formatCardCount(
              onList: true,
              seasonsDone: 4,
              seasonsTotal: 4,
            ),
            showMark: true,
          ),
        ),
        _foot(
          'Franchise, a season left',
          CardFoot(
            status: EntryStatus.completed,
            finished: false,
            count: formatCardCount(
              onList: true,
              seasonsDone: 1,
              seasonsTotal: 2,
            ),
            showMark: true,
          ),
        ),
        _foot(
          'No total yet',
          CardFoot(
            status: EntryStatus.planned,
            count: formatCardCount(onList: true),
            showMark: true,
          ),
        ),
        _foot(
          'One-status tab',
          CardFoot(
            status: EntryStatus.onHold,
            count: formatCardCount(onList: true, watched: 3, total: 12),
          ),
        ),
        _foot(
          'Hovered, no room for the word',
          CardFoot(
            status: EntryStatus.rewatching,
            count: formatCardCount(onList: true, watched: 1071, total: 1100),
            showMark: true,
            showWord: true,
          ),
        ),
        _foot(
          'Airing, not on your list',
          CardFoot(count: formatCardCount(onList: false, total: 12, aired: 8)),
        ),
        _foot(
          'Not on your list',
          CardFoot(count: formatCardCount(onList: false, total: 12)),
        ),
        _foot(
          'No total from MAL',
          CardFoot(count: formatCardCount(onList: false)),
        ),
      ]),
      const SizedBox(height: Tokens.space5),
      _samples(Tokens.space3, [
        for (final type in _types) KeyCaps(formatType(type)),
      ]),
      const SizedBox(height: Tokens.space5),
      _samples(Tokens.space5, [
        MalScoreLine(
          score: 9.29,
          when: formatCardWhen('2023-09-29', notAired: false),
        ),
        MalScoreLine(score: null, when: formatCardWhen(null, notAired: false)),
        MalScoreLine(
          score: null,
          when: formatCardWhen('2027-01-12', notAired: true),
        ),
        const MalScoreLine(score: 8.4),
      ]),
      const SizedBox(height: Tokens.space5),
      _popovers(),
    ],
  );
}

/// A title as the short fetch gives it, or with the full fetch's synopsis
/// and genres too.
TitleDetails _sampleDetails({required bool full}) => TitleDetails(
  malId: 52991,
  name: 'Sousou no Frieren',
  otherNames: const ["Frieren: Beyond Journey's End", '葬送のフリーレン'],
  isFull: full,
  fetchedAt: 0,
  airingStatus: 'finished_airing',
  episodes: 28,
  startDate: '2023-09-29',
  endDate: '2024-03-22',
  secondsPerEpisode: 1440,
  // made up, so the repo carries no MAL text
  synopsis: full
      ? 'The demon king is beaten and the party parts ways. An elf who will '
            'outlive them all sets out to learn what those ten years meant, '
            'one journey at a time, long after the others have grown old.'
      : null,
  genres: full ? const ['Adventure', 'Drama', 'Fantasy'] : const [],
);

/// The card's details popover: full, while the full fetch runs, and offline
/// with no full fetch stored.
Widget _popovers() => _samples(Tokens.space4, [
  for (final (details, fetch) in [
    (_sampleDetails(full: true), DetailFetch.idle),
    (_sampleDetails(full: false), DetailFetch.running),
    (_sampleDetails(full: false), DetailFetch.offline),
  ])
    DetailsPanel(
      child: CardDetails(
        name: details.name,
        details: details,
        fetch: fetch,
        status: EntryStatus.watching,
        onStatusMenu: (_) {},
      ),
    ),
]);

Widget _samples(double gap, List<Widget> children) =>
    Wrap(spacing: gap, runSpacing: gap, children: children);

Widget _foot(String label, CardFoot foot) => SizedBox(
  width: Tokens.gridCardMinWidth,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.caption(Tokens.inkMuted)),
      const SizedBox(height: Tokens.space2),
      ColoredBox(color: Tokens.wellFill, child: foot),
    ],
  ),
);
