import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../components/more_button.dart';
import '../design/tokens.dart';
import '../library/library_row.dart';
import '../screens/library/library_grid_card.dart';
import '../screens/library/library_list_row.dart';

LibraryRow _row({
  required String name,
  required String status,
  required int watched,
  int? episodes,
  int? score,
  String mediaType = 'tv',
  String? startDate,
  int? malId,
  bool hasDetails = true,
  int? seasonsDone,
  int? seasonsTotal,
}) => LibraryRow(
  current: LibraryEntry(
    entryId: name,
    name: name,
    status: status,
    episodesWatched: watched,
    addedAt: 0,
    changedAt: 0,
    score: score,
    malId: malId,
    hasDetails: hasDetails,
    episodes: episodes,
    mediaType: mediaType,
    startDate: startDate,
  ),
  entryIds: [name],
  addedAt: 0,
  changedAt: 0,
  seasonsDone: seasonsDone,
  seasonsTotal: seasonsTotal,
);

final _samples = [
  _row(
    name: 'Sousou no Frieren',
    status: 'watching',
    watched: 4,
    episodes: 28,
    score: 9,
    startDate: '2023-09-29',
    malId: 1,
  ),
  _row(
    name: 'Kaguya-sama: Love Is War',
    status: 'completed',
    watched: 37,
    episodes: 37,
    score: 10,
    startDate: '2019-01-12',
    malId: 2,
    seasonsDone: 3,
    seasonsTotal: 3,
  ),
  _row(
    name: 'Mushoku Tensei',
    status: 'completed',
    watched: 11,
    episodes: 11,
    score: 8,
    startDate: '2021-01-11',
    malId: 3,
    seasonsDone: 1,
    seasonsTotal: 2,
  ),
  _row(
    name: 'Look Back',
    status: 'plan_to_watch',
    watched: 0,
    episodes: 1,
    mediaType: 'movie',
    startDate: '2024-06-28',
    malId: 4,
  ),
  _row(
    name: 'A name that goes on for much longer than the room it is given',
    status: 'on_hold',
    watched: 6,
    episodes: 24,
    startDate: '2018',
    malId: 5,
  ),
  _row(name: 'Saved name only', status: 'dropped', watched: 2),
  _row(
    name: '',
    status: 'plan_to_watch',
    watched: 0,
    malId: 6,
    hasDetails: false,
  ),
];

/// The Library's list rows and grid cards as the screen will draw them, on the
/// All tab (status shown) and on another tab (status left out). Covers are the
/// blank squares, since no files are kept here.
class LibraryRowsSection extends StatelessWidget {
  const LibraryRowsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [coverStoreProvider.overrideWithValue(null)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Tokens.space4,
            runSpacing: Tokens.space4,
            children: [
              for (final row in _samples.take(6))
                SizedBox(
                  width: Tokens.gridCardMinWidth,
                  child: LibraryGridCard(
                    row: row,
                    showStatus: true,
                    onOpen: () {},
                    onContextMenu: (_) {},
                  ),
                ),
            ],
          ),
          const SizedBox(height: Tokens.space5),
          for (final row in _samples)
            LibraryListRow(
              row: row,
              showStatus: true,
              onOpen: () {},
              onCheck: (_) {},
              onContextMenu: (_) {},
              menu: MoreButton(onPressed: () {}),
            ),
          const SizedBox(height: Tokens.space5),
          for (final row in _samples.take(2))
            LibraryListRow(
              row: row,
              showStatus: false,
              onOpen: () {},
              onCheck: (_) {},
              onContextMenu: (_) {},
              menu: MoreButton(onPressed: () {}),
            ),
        ],
      ),
    );
  }
}
