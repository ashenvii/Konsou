import 'package:flutter/widgets.dart';

import '../app/detail_providers.dart';
import '../components/card_foot.dart';
import '../components/key_cap.dart';
import '../components/mal_score_line.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/entry_status.dart';
import '../library/library_row.dart';
import '../detail/title_details.dart';
import '../library/row_labels.dart';
import '../screens/library/card_details.dart';
import '../screens/library/quick_panel.dart';

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
          'Watching',
          CardFoot(
            status: EntryStatus.watching,
            count: countCard(onList: true, watched: 9, total: 28),
          ),
        ),
        _foot(
          'Franchise, done',
          CardFoot(
            status: EntryStatus.completed,
            count: countCard(onList: true, watched: 13, total: 13),
            season: 4,
          ),
        ),
        _foot(
          'Franchise, season 2',
          CardFoot(
            status: EntryStatus.watching,
            count: countCard(onList: true, watched: 3, total: 12),
            season: 2,
          ),
        ),
        _foot(
          'No total yet',
          CardFoot(status: EntryStatus.planned, count: countCard(onList: true)),
        ),
        _foot(
          'On hold',
          CardFoot(
            status: EntryStatus.onHold,
            count: countCard(onList: true, watched: 3, total: 12),
          ),
        ),
        _foot(
          'Long counts',
          CardFoot(
            status: EntryStatus.rewatching,
            count: countCard(onList: true, watched: 1071, total: 1100),
          ),
        ),
        _foot(
          'Not on your list',
          CardFoot(count: countCard(onList: false, total: 12)),
        ),
        _foot('No total from MAL', CardFoot(count: countCard(onList: false))),
      ]),
      const SizedBox(height: Tokens.space5),
      _samples(Tokens.space3, [
        for (final type in _types) KeyCaps(formatType(type)),
      ]),
      const SizedBox(height: Tokens.space5),
      _samples(Tokens.space5, [
        const MalScoreLine(score: 9.29),
        const MalScoreLine(score: null),
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

/// The quick panel, one height in every state: watching with the full fetch
/// in, a franchise while the full fetch runs, planned offline with no full
/// fetch stored, dropped (a worded status), and a title with no MAL page.
Widget _popovers() => _samples(Tokens.space4, [
  for (final (status, details, fetch, seasons, notLinked) in [
    (
      EntryStatus.watching,
      _sampleDetails(full: true),
      DetailFetch.idle,
      1,
      false,
    ),
    (
      EntryStatus.completed,
      _sampleDetails(full: false),
      DetailFetch.running,
      3,
      false,
    ),
    (
      EntryStatus.planned,
      _sampleDetails(full: false),
      DetailFetch.offline,
      1,
      false,
    ),
    (
      EntryStatus.dropped,
      _sampleDetails(full: true),
      DetailFetch.idle,
      1,
      false,
    ),
    (EntryStatus.onHold, null, DetailFetch.idle, 1, true),
  ])
    Builder(
      builder: (context) {
        final row = LibraryRow(
          current: LibraryEntry(
            entryId: 'gallery',
            name: details?.name ?? 'Saved name only',
            status: status,
            episodesWatched: status == EntryStatus.planned ? 0 : 9,
            episodes: 28,
            malScore: notLinked ? null : 9.29,
            malId: notLinked ? null : 52991,
            hasDetails: !notLinked,
            addedAt: 0,
            changedAt: 0,
          ),
          entryIds: [for (var i = 0; i < seasons; i++) 'gallery $i'],
          addedAt: 0,
          changedAt: 0,
          seasonsDone: seasons > 1 ? seasons : null,
          seasonsTotal: seasons > 1 ? seasons : null,
          seasonNumber: seasons > 1 ? seasons : null,
        );
        return QuickPanel(
          row: row,
          details: CardDetails(
            name: row.name,
            details: details,
            fetch: fetch,
            malScore: row.malScore,
            notLinked: row.isNotLinked,
            progress: formatPanelProgress(row),
            trailingRoom: QuickPanel.cornerRoom,
          ),
          onStatus: (_) {},
          onOpen: () {},
          onRemove: () {},
          onClose: () {},
        );
      },
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
