import 'package:flutter/widgets.dart';

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

class LibraryRowList extends StatelessWidget {
  const LibraryRowList({
    super.key,
    required this.rows,
    required this.libraryIsEmpty,
    required this.finding,
    required this.showStatus,
    required this.keptIds,
    required this.layout,
    required this.sort,
    required this.onDiscover,
    required this.onOpen,
  });

  final List<LibraryRow> rows;

  final Set<String> keptIds;
  final bool libraryIsEmpty;

  final bool finding;
  final bool showStatus;
  final LibraryLayout layout;
  final LibrarySort sort;
  final VoidCallback onDiscover;
  final ValueChanged<LibraryRow> onOpen;

  bool _statusShown(LibraryRow row) =>
      showStatus || keptIds.contains(row.entryId);

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

    if (sort == LibrarySort.title) {
      // A to Z keeps the rows under a heading for each letter
      return LetteredRows(rows: rows, layout: layout, itemBuilder: _item);
    }
    // rows a screen either side are built, so they load ahead of the view
    const ahead = ScrollCacheExtent.viewport(1);
    return SmoothScroll(
      builder: (context, controller) => layout == LibraryLayout.grid
          ? LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                controller: controller,
                scrollCacheExtent: ahead,
                padding: PageFrame.content,
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
              padding: PageFrame.content,
              itemExtent: Tokens.listRowHeight,
              itemCount: rows.length,
              itemBuilder: (context, index) => _item(context, rows[index]),
            ),
    );
  }

  Widget _item(BuildContext context, LibraryRow row) {
    return LibraryRowMenu(
      row: row,
      onOpen: onOpen,
      builder: (context, handle) => layout == LibraryLayout.grid
          ? LibraryGridCard(
              row: row,
              showStatus: _statusShown(row),
              onOpen: () => onOpen(row),
              onContextMenu: handle.openAt,
            )
          : LibraryListRow(
              row: row,
              showStatus: _statusShown(row),
              onOpen: () => onOpen(row),
              onCheck: (done) => editLibraryRow(
                context,
                row,
                (actions) => done
                    ? actions.setStatus(row.entryId, EntryStatus.completed)
                    : actions.uncheck(row.entryId),
              ),
              onContextMenu: handle.openAt,
              menu: Builder(
                builder: (context) => IconSquareButton(
                  icon: AppIcons.more,
                  label: 'More',
                  // open the menu under the button, not under the row
                  onPressed: () => openMenuBelow(context, handle),
                ),
              ),
            ),
    );
  }
}
