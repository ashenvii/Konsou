import 'package:flutter/widgets.dart';

import '../../components/dithered_gradient.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../components/page_frame.dart';
import '../../components/presence.dart';
import '../../components/hold_while_scrolling.dart';
import '../../design/tokens.dart';
import '../../library/library_row.dart';
import '../../library/library_view.dart';
import 'library_skeleton.dart';
import 'library_status_switcher.dart';
import 'library_sort_button.dart';
import 'library_layout_switch.dart';
import 'library_message.dart';
import 'library_find.dart';
import 'library_row_list.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({
    super.key,
    required this.onDiscover,
    required this.onOpen,
  });

  final VoidCallback onDiscover;
  final ValueChanged<LibraryRow> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // a reload that found nothing new, or only flipped to loading, is not a rebuild
    final loadedRows = ref
        .watch(libraryRowsProvider.select((rows) => RowsSnapshot(rows.value)))
        .rows;
    final failed = ref.watch(
      libraryRowsProvider.select((rows) => rows.hasError),
    );
    final tab = ref.watch(libraryTabChoiceProvider);
    final sort =
        ref.watch(librarySortChoiceProvider).value ?? LibrarySort.recent;
    final kept = ref.watch(libraryKeptProvider);
    final layout =
        ref.watch(libraryLayoutChoiceProvider).value ?? LibraryLayout.grid;
    final find = ref.watch(libraryFindChoiceProvider);
    final matches = ref.watch(libraryFindMatchesProvider).value;
    // find narrows the rows first, so the counts follow it
    final all = loadedRows == null
        ? null
        : filterRowsByFind(loadedRows, matches);
    final counts = all == null ? null : countTabs(all);
    // the console's chassis behind the page, lighter at the top
    return DitheredGradient(
      top: Tokens.chassisTop,
      bottom: Tokens.chassisBottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: PageFrame.top,
            child: Row(
              children: [
                Expanded(
                  // a window under the minimum width shrinks the heading instead of overflowing
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: LibraryStatusSwitcher(
                      selected: tab,
                      counts: counts,
                      onSelect: ref
                          .read(libraryTabChoiceProvider.notifier)
                          .select,
                    ),
                  ),
                ),
                LibraryLayoutSwitch(
                  layout: layout,
                  onLayout: ref
                      .read(libraryLayoutChoiceProvider.notifier)
                      .select,
                ),
                // the switch sits on the window's centre, not the page's
                SizedBox(width: PageFrame.railInset),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LibraryFind(),
                        const SizedBox(width: Tokens.space2),
                        LibrarySortButton(
                          sort: sort,
                          onSort: ref
                              .read(librarySortChoiceProvider.notifier)
                              .select,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: all == null
                ? (failed
                      ? const LibraryMessage('Your library could not be read.')
                      : LibrarySkeleton(layout: layout))
                // a new status, sort, view or search fades the new rows in
                // instead of cutting to them
                : Presence(
                    key: ValueKey('fade $tab $sort $layout ${find ?? ''}'),
                    visible: true,
                    child: HoldWhileScrolling(
                      // a new status, sort, view or search starts at the top, at
                      // once. the view is here too: swapping the scroll view
                      // mid-scroll would never report that scroll's end
                      key: ValueKey('$tab $sort $layout ${find ?? ''}'),
                      value: (
                        rows: RowsSnapshot(
                          sortRows(filterRowsByTab(all, tab, keep: kept), sort),
                        ),
                        kept: kept,
                      ),
                      builder: (context, held) => LibraryRowList(
                        rows: held.rows.rows!,
                        keptIds: held.kept,
                        libraryIsEmpty: loadedRows!.isEmpty,
                        finding: matches != null,
                        showStatus: tab == LibraryTab.all,
                        layout: layout,
                        sort: sort,
                        onDiscover: onDiscover,
                        onOpen: onOpen,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
