import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../components/icon_square_button.dart';
import '../design/tokens.dart';
import '../icons/app_icons.dart';
import '../library/entry_status.dart';
import '../library/library_row.dart';
import '../screens/library/library_grid_card.dart';
import '../screens/library/library_list_row.dart';

LibraryRow _row({
  required String name,
  required EntryStatus status,
  required int watched,
  int? episodes,
  int? score,
  double? malScore,
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
    malScore: malScore,
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

final sampleRows = [
  _row(
    name: 'Sousou no Frieren',
    status: EntryStatus.watching,
    watched: 4,
    episodes: 28,
    score: 9,
    malScore: 9.29,
    startDate: '2023-09-29',
    malId: 1,
  ),
  _row(
    name: 'Kaguya-sama: Love Is War',
    status: EntryStatus.completed,
    watched: 37,
    episodes: 37,
    score: 10,
    malScore: 8.4,
    startDate: '2019-01-12',
    malId: 2,
    seasonsDone: 3,
    seasonsTotal: 3,
  ),
  _row(
    name: 'Mushoku Tensei',
    status: EntryStatus.completed,
    watched: 11,
    episodes: 11,
    score: 8,
    malScore: 8.36,
    startDate: '2021-01-11',
    malId: 3,
    seasonsDone: 1,
    seasonsTotal: 2,
  ),
  _row(
    name: 'Look Back',
    status: EntryStatus.planned,
    watched: 0,
    episodes: 1,
    mediaType: 'movie',
    malScore: 8.6,
    startDate: '2024-06-28',
    malId: 4,
  ),
  _row(
    name: 'A name that goes on for much longer than the room it is given',
    status: EntryStatus.onHold,
    watched: 6,
    episodes: 24,
    startDate: '2018',
    malId: 5,
  ),
  _row(name: 'Saved name only', status: EntryStatus.dropped, watched: 2),
  _row(
    name: '',
    status: EntryStatus.planned,
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
              for (final row in sampleRows.take(6))
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
          for (final row in sampleRows) _listRow(row, showStatus: true),
          const SizedBox(height: Tokens.space5),
          for (final row in sampleRows.take(2))
            _listRow(row, showStatus: false),
        ],
      ),
    );
  }
}

Widget _listRow(LibraryRow row, {required bool showStatus}) => LibraryListRow(
  row: row,
  showStatus: showStatus,
  onOpen: () {},
  onCheck: (_) {},
  onContextMenu: (_) {},
  menu: IconSquareButton(icon: AppIcons.more, label: 'More', onPressed: () {}),
);
