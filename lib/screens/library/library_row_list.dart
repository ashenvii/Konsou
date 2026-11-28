import 'package:flutter/widgets.dart';

import '../../app/score_fill.dart';
import '../../components/app_button.dart';
import '../../components/icon_square_button.dart';
import '../../components/page_frame.dart';
import '../../components/smooth_scroll.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/library_view.dart';
import 'grid_layout.dart';
import 'library_grid_card.dart';
import 'lettered_rows.dart';
import 'library_list_row.dart';
import 'library_message.dart';
import 'library_row_menu.dart';

/// The Library's rows, or a message when there are none or none match.
class LibraryRowList extends StatelessWidget {
  const LibraryRowList({
    super.key,
    required this.rows,
    required this.libraryIsEmpty,
    required this.finding,
    required this.layout,
    required this.sort,
    required this.onDiscover,
    required this.onOpen,
    this.columnSort,
    this.showStatus = true,
    this.keptIds = const {},
    this.topInset = 0,
    this.pinned = 0,
    this.dimmed = false,
  });

  /// A quick panel is open: every cover but its title's is grey.
  final bool dimmed;

  final List<LibraryRow> rows;

  final bool libraryIsEmpty;

  final bool finding;
  final LibraryLayout layout;

  /// The sort menu's choice.
  final LibrarySort sort;

  /// The list header bar's sort, which [rows] are already in; null when off.
  final ColumnSort? columnSort;

  /// A tab that mixes statuses, so rows and cards name each one.
  final bool showStatus;

  /// Rows kept in view after an edit moved them out of the tab: a card
  /// names their status even on a tab of one status.
  final Set<String> keptIds;

  /// Room above the first row for the page's top, which the rows scroll
  /// under once it has folded to [pinned] high.
  final double topInset;
  final double pinned;
  final VoidCallback onDiscover;
  final ValueChanged<LibraryRow> onOpen;

  @override
  Widget build(BuildContext context) {
    if (libraryIsEmpty) {
      return LibraryMessage(
        'Your library is empty.',
        action: AppButton(label: 'Go to Discover', onPressed: onDiscover),
      );
    }
    if (rows.isEmpty) {
      return LibraryMessage(
        finding ? 'Nothing matches that.' : 'Nothing here.',
      );
    }

    if (sort == LibrarySort.title && columnSort == null) {
      // A to Z keeps the rows under a heading for each letter
      return LetteredRows(
        rows: rows,
        layout: layout,
        topInset: topInset,
        pinned: pinned,
        itemBuilder: _item,
      );
    }
    return _plain();
  }

  Widget _plain() {
    // rows a screen either side are built, so they load ahead of the view
    const ahead = ScrollCacheExtent.viewport(1);
    return SmoothScroll(
      builder: (context, controller) => layout == LibraryLayout.grid
          ? LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                controller: controller,
                scrollCacheExtent: ahead,
                // room above the first row for a hovered card's lift
                padding: PageFrame.content.copyWith(
                  top: topInset + Tokens.cardLift,
                ),
                gridDelegate: GridLayout.forWidth(
                  constraints.maxWidth - PageFrame.content.horizontal,
                  textScaler: MediaQuery.textScalerOf(context),
                ).delegate,
                itemCount: rows.length,
                itemBuilder: (context, index) => _item(context, rows[index]),
              ),
            )
          : ListView.builder(
              controller: controller,
              scrollCacheExtent: ahead,
              // the same room on the right as A to Z gives its letter strip,
              // so a row is as wide under every sort
              padding: PageFrame.content.copyWith(
                top: topInset,
                right: PageFrame.content.right + LetteredRows.stripGutter,
              ),
              itemExtent: Tokens.listRowHeight,
              itemCount: rows.length,
              itemBuilder: (context, index) => _item(context, rows[index]),
            ),
    );
  }

  Widget _item(BuildContext context, LibraryRow row) {
    final grid = layout == LibraryLayout.grid;
    return LibraryRowMenu(
      row: row,
      onOpen: onOpen,
      grid: grid,
      builder: (context, handle) => grid
          ? LibraryGridCard(
              row: row,
              showStatus: showStatus || keptIds.contains(row.entryId),
              onOpen: () => onOpen(row),
              onContextMenu: (_) => openQuickPanel(context, handle, grid: true),
              held: handle.isOpen,
              faded: dimmed && !handle.isOpen,
            )
          : ScoreFill(
              malId: row.malId,
              pending: row.isScorePending,
              child: LibraryListRow(
                row: row,
                showStatus: showStatus,
                onOpen: () => onOpen(row),
                onCheck: (done) => editLibraryRow(
                  context,
                  row,
                  (actions) => done
                      ? actions.setStatus(row.entryId, EntryStatus.completed)
                      : actions.uncheck(row.entryId),
                ),
                onContextMenu: (_) =>
                    openQuickPanel(context, handle, grid: false),
                menuShown: handle.isOpen,
                faded: dimmed && !handle.isOpen,
                menu: IconSquareButton(
                  icon: AppIcons.more,
                  label: 'More',
                  onPressed: () => openQuickPanel(context, handle, grid: false),
                ),
              ),
            ),
    );
  }
}
