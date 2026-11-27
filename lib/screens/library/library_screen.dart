import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../components/dithered_gradient.dart';
import '../../components/hold_while_scrolling.dart';
import '../../components/page_frame.dart';
import '../../components/presence.dart';
import '../../design/tokens.dart';
import '../../library/library_row.dart';
import '../../library/library_view.dart';
import 'library_find.dart';
import 'library_layout_switch.dart';
import 'library_message.dart';
import 'library_row_list.dart';
import 'library_skeleton.dart';
import 'library_sort_button.dart';
import 'library_status_switcher.dart';
import 'library_top.dart';
import 'lettered_rows.dart';
import 'list_columns.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({
    super.key,
    required this.onDiscover,
    required this.onOpen,
  });

  final VoidCallback onDiscover;
  final ValueChanged<LibraryRow> onOpen;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // how far the rows have scrolled, which folds the top
  final _scrolled = ValueNotifier<double>(0);
  String? _shownKey;

  // the order the rows had when a quick panel opened, so an edit made in it
  // does not move the row out from under it
  List<String>? _heldOrder;

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      _scrolled.value = notification.metrics.pixels;
    }
    return false;
  }

  List<LibraryRow> _hold(List<LibraryRow> rows, {required bool hold}) {
    if (!hold) {
      _heldOrder = null;
      return rows;
    }
    final order = _heldOrder ??= [for (final row in rows) row.entryId];
    final place = {for (final (i, id) in order.indexed) id: i};
    // rows that were not there when it opened go after the rest
    return [...rows]..sort(
      (a, b) => (place[a.entryId] ?? order.length).compareTo(
        place[b.entryId] ?? order.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final panelOpen = ref.watch(libraryPanelOpenProvider) > 0;
    final list = layout == LibraryLayout.list;
    // the header bar's sort only orders the list view
    final columnSort = list ? ref.watch(libraryColumnSortChoiceProvider) : null;
    final matches = ref.watch(libraryFindMatchesProvider).value;
    // find narrows the rows first, so the counts follow it
    final all = loadedRows == null
        ? null
        : filterRowsByFind(loadedRows, matches);
    final counts = all == null ? null : countTabs(all);
    final rest = LibraryTop.restHeight(list: list);
    final pinned = LibraryTop.pinnedHeight(list: list);

    // a new status, sort, view or search starts at the top, unfolded
    final key = '$tab $sort $columnSort $layout ${find ?? ''}';
    if (key != _shownKey) {
      _shownKey = key;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrolled.value = 0;
      });
    }

    final sortButton = LibrarySortButton(
      sort: sort,
      onSort: ref.read(librarySortChoiceProvider.notifier).select,
    );
    final heading = Padding(
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
                onSelect: ref.read(libraryTabChoiceProvider.notifier).select,
              ),
            ),
          ),
          LibraryLayoutSwitch(
            layout: layout,
            onLayout: ref.read(libraryLayoutChoiceProvider.notifier).select,
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
                  sortButton,
                ],
              ),
            ),
          ),
        ],
      ),
    );
    // the folded top's short title opens the same status menu
    final title = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: LibraryStatusSwitcher(
        compact: true,
        selected: tab,
        counts: counts,
        onSelect: ref.read(libraryTabChoiceProvider.notifier).select,
      ),
    );

    final Widget content;
    if (all == null) {
      content = Padding(
        padding: EdgeInsets.only(top: rest),
        child: failed
            ? const LibraryMessage('Your library could not be read.')
            : LibrarySkeleton(layout: layout),
      );
    } else {
      final sorted = switch (columnSort) {
        final by? => sortRowsByColumn(
          filterRowsByTab(all, tab, keep: kept),
          by,
        ),
        null => sortRows(filterRowsByTab(all, tab, keep: kept), sort),
      };
      // a new status, sort, view or search fades the new rows in instead
      // of cutting to them
      content = Presence(
        key: ValueKey('fade $key'),
        visible: true,
        child: HoldWhileScrolling(
          // the view is in the key too: swapping the scroll view mid-scroll
          // would never report that scroll's end
          key: ValueKey(key),
          value: (
            rows: RowsSnapshot(_hold(sorted, hold: panelOpen)),
            kept: kept,
          ),
          builder: (context, held) {
            final rows = held.rows.rows!;
            final message = loadedRows!.isEmpty || rows.isEmpty;
            return Padding(
              // a message has no scroll view to take the room itself
              padding: EdgeInsets.only(top: message ? rest : 0),
              child: LibraryRowList(
                rows: rows,
                libraryIsEmpty: loadedRows.isEmpty,
                finding: matches != null,
                layout: layout,
                sort: sort,
                columnSort: columnSort,
                showStatus: tab == LibraryTab.all,
                keptIds: held.kept,
                topInset: message ? 0 : rest,
                pinned: pinned,
                dimmed: panelOpen,
                onDiscover: widget.onDiscover,
                onOpen: widget.onOpen,
              ),
            );
          },
        ),
      );
    }

    // the console's chassis behind the page, lighter at the top
    return DitheredGradient(
      top: Tokens.chassisTop,
      bottom: Tokens.chassisBottom,
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: content,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: _scrolled,
              builder: (context, scrolled, _) => LibraryTop(
                // an open Find unfolds it, so the field is never hidden
                fold: !list || all == null || find != null
                    ? 0
                    : (scrolled / (rest - pinned)).clamp(0.0, 1.0),
                covering: scrolled > 0,
                heading: heading,
                title: title,
                captions: list
                    ? (lead) => LibraryListHeader(
                        shown: columnSort ?? columnSortOf(sort),
                        onPick: (column) => ref
                            .read(libraryColumnSortChoiceProvider.notifier)
                            .pick(column, sort),
                        endInset: LetteredRows.stripGutter,
                        showStatus: tab == LibraryTab.all,
                        lead: lead,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
