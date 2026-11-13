import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/entry_actions.dart';
import '../../app/library_providers.dart';
import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/countdown.dart';
import '../../components/find_field.dart';
import '../../components/heading_switcher.dart';
import '../../components/icon_square_button.dart';
import '../../components/more_button.dart';
import '../../components/menu_switcher.dart';
import '../../components/page_frame.dart';
import '../../components/hold_while_scrolling.dart';
import '../../components/motion.dart';
import '../../components/smooth_scroll.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';
import '../../library/count_format.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/library_view.dart';
import 'entry_menu.dart';
import 'grid_layout.dart';
import 'library_grid_card.dart';
import 'lettered_rows.dart';
import 'library_list_row.dart';
import 'library_skeleton.dart';
import 'row_marker.dart';

String _tabLabel(LibraryTab tab) => switch (tab) {
  LibraryTab.all => 'All',
  LibraryTab.watching => 'Watching',
  LibraryTab.planned => 'Planned',
  LibraryTab.completed => 'Completed',
  LibraryTab.onHold => 'On hold',
  LibraryTab.dropped => 'Dropped',
  LibraryTab.notInterested => 'Not interested',
};

String _sortLabel(LibrarySort sort) => switch (sort) {
  LibrarySort.recent => 'Recent',
  LibrarySort.title => 'A to Z',
};

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
    final sort = ref.watch(librarySortChoiceProvider);
    final kept = ref.watch(libraryKeptProvider);
    final layout =
        ref.watch(libraryLayoutChoiceProvider).value ?? LibraryLayout.grid;
    final find = ref.watch(libraryFindChoiceProvider);
    final matches = ref.watch(libraryFindMatchesProvider).value;
    // find narrows the rows first, so the counts follow it
    final all = loadedRows == null ? null : rowsMatching(loadedRows, matches);
    final counts = all == null ? null : countTabs(all);
    return Column(
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
                  child: _StatusSwitcher(
                    selected: tab,
                    counts: counts,
                    onSelect: ref
                        .read(libraryTabChoiceProvider.notifier)
                        .select,
                  ),
                ),
              ),
              _LayoutSwitch(
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
                      const _Find(),
                      const SizedBox(width: Tokens.space2),
                      _SortButton(
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
                    ? const _Message('Your library could not be read.')
                    : LibrarySkeleton(layout: layout))
              : HoldWhileScrolling(
                  // a new status, sort, view or search starts at the top, at
                  // once. the view is here too: swapping the scroll view
                  // mid-scroll would never report that scroll's end
                  key: ValueKey('$tab $sort $layout ${find ?? ''}'),
                  value: (
                    rows: RowsSnapshot(
                      sortRows(rowsInTab(all, tab, keep: kept), sort),
                    ),
                    kept: kept,
                  ),
                  builder: (context, held) => _Rows(
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
      ],
    );
  }
}

class _StatusSwitcher extends StatelessWidget {
  const _StatusSwitcher({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  final LibraryTab selected;
  final Map<LibraryTab, int>? counts;
  final ValueChanged<LibraryTab> onSelect;

  @override
  Widget build(BuildContext context) {
    String? countOf(LibraryTab tab) {
      final count = counts?[tab];
      return count == null ? null : formatCount(count);
    }

    return HeadingSwitcher(
      title: 'Library',
      current: _tabLabel(selected),
      count: countOf(selected),
      footnote: 'Alt + 1 to 7 switches without opening',
      entries: [
        for (final tab in LibraryTab.values)
          MenuEntry(
            label: _tabLabel(tab),
            selected: tab == selected,
            count: countOf(tab) ?? '0',
            // a hairline after All and before On hold
            dividerAbove:
                tab == LibraryTab.watching || tab == LibraryTab.onHold,
            onPressed: () => onSelect(tab),
          ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSort});

  final LibrarySort sort;
  final ValueChanged<LibrarySort> onSort;

  @override
  Widget build(BuildContext context) {
    return MenuSwitcher(
      current: _sortLabel(sort),
      style: AppText.label(Tokens.ink),
      entries: [
        for (final choice in LibrarySort.values)
          MenuEntry(
            label: _sortLabel(choice),
            selected: choice == sort,
            onPressed: () => onSort(choice),
          ),
      ],
    );
  }
}

class _LayoutSwitch extends StatelessWidget {
  const _LayoutSwitch({required this.layout, required this.onLayout});

  final LibraryLayout layout;
  final ValueChanged<LibraryLayout> onLayout;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconSquareButton(
          icon: AppIcons.grid,
          label: 'Grid view',
          selected: layout == LibraryLayout.grid,
          onPressed: () => onLayout(LibraryLayout.grid),
        ),
        const SizedBox(width: Tokens.space1),
        IconSquareButton(
          icon: AppIcons.list,
          label: 'List view',
          selected: layout == LibraryLayout.list,
          onPressed: () => onLayout(LibraryLayout.list),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PageFrame.content,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Tokens.space5),
          Text(text, style: AppText.label(Tokens.inkSoft)),
          if (action != null) ...[
            const SizedBox(height: Tokens.space4),
            action!,
          ],
        ],
      ),
    );
  }
}

class _Find extends ConsumerStatefulWidget {
  const _Find();

  @override
  ConsumerState<_Find> createState() => _FindState();
}

class _FindState extends ConsumerState<_Find> with HoverDelaysState<_Find> {
  LibraryFindChoice get _choice => ref.read(libraryFindChoiceProvider.notifier);

  @override
  void hoverOpen() => _choice.open();

  // typed text keeps it open
  @override
  void hoverClose() {
    if ((ref.read(libraryFindChoiceProvider) ?? '').isEmpty) _choice.close();
  }

  // the field stays drawn while it slides shut, then the magnifier comes back
  var _fieldShown = false;

  @override
  Widget build(BuildContext context) {
    final find = ref.watch(libraryFindChoiceProvider);
    final open = find != null;
    if (open) _fieldShown = true;
    return MouseRegion(
      onEnter: (_) => hoverDelays.entered(isOpen: open),
      // only an empty field closes when the pointer leaves
      onExit: (_) => hoverDelays.left(
        isOpen: ref.read(libraryFindChoiceProvider)?.isEmpty ?? false,
      ),
      child: AnimatedContainer(
        duration: chooseMotionDuration(context, Tokens.motionSlide),
        curve: Curves.easeInOut,
        width: open ? Tokens.findFieldWidth : Tokens.controlHeight,
        height: Tokens.controlHeight,
        onEnd: () {
          if (!open && _fieldShown) setState(() => _fieldShown = false);
        },
        child: _fieldShown
            ? ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerRight,
                  minWidth: Tokens.findFieldWidth,
                  maxWidth: Tokens.findFieldWidth,
                  child: FindField(
                    initial: find ?? '',
                    placeholder: 'Search your library',
                    onChanged: _choice.change,
                    onClose: _choice.close,
                  ),
                ),
              )
            : IconSquareButton(
                icon: AppIcons.search,
                label: 'Find',
                onPressed: _choice.open,
              ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({
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
      return _Message(
        'Your library is empty.',
        action: AppButton(label: 'Go to Discover', onPressed: onDiscover),
      );
    }
    if (rows.isEmpty) {
      return _Message(finding ? 'Nothing matches that.' : 'Nothing here.');
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
    return _RowMenu(
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
              onCheck: (done) => _edit(
                context,
                row,
                (e) => done
                    ? e.setStatus(row.entryId, EntryStatus.completed)
                    : e.uncheck(row.entryId),
              ),
              onContextMenu: handle.openAt,
              menu: Builder(
                builder: (context) => MoreButton(
                  onPressed: () {
                    // open the menu under the button, not under the row
                    final box = context.findRenderObject()! as RenderBox;
                    handle.openAt(
                      box.localToGlobal(Offset(0, box.size.height)),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

Future<void> _edit(
  BuildContext context,
  LibraryRow row,
  Future<Object?> Function(EntryActions actions) action, {
  bool keepInView = true,
}) async {
  final scope = ProviderScope.containerOf(context);
  // the row stays where it is, showing its new status, until the tab changes.
  // kept before the edit, so the reload the edit starts never drops the row
  if (keepInView) scope.read(libraryKeptProvider.notifier).keep(row.entryId);
  await action(scope.read(entryActionsProvider));
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.row,
    required this.onOpen,
    required this.builder,
  });

  final LibraryRow row;
  final ValueChanged<LibraryRow> onOpen;
  final Widget Function(BuildContext context, PopoverHandle handle) builder;

  @override
  Widget build(BuildContext context) {
    return AppPopover(
      key: ValueKey(row.entryId),
      builder: (context, handle) => RowMarker(
        entryId: row.entryId,
        // the Menu key opens it under the row, as the three dots do
        openMenu: () {
          final box = context.findRenderObject()! as RenderBox;
          handle.openAt(box.localToGlobal(Offset(0, box.size.height)));
        },
        child: builder(context, handle),
      ),
      popoverBuilder: (context, handle) => EntryMenu(
        row: row,
        onClose: handle.close,
        onStatus: (status) =>
            _edit(context, row, (e) => e.setStatus(row.entryId, status)),
        onAddEpisode: () =>
            _edit(context, row, (e) => e.addEpisode(row.entryId)),
        onRewatch: () => _edit(context, row, (e) => e.rewatch(row.entryId)),
        onOpen: () => onOpen(row),
        onRemove: () => _edit(
          context,
          row,
          (e) => e.remove(row.entryIds),
          keepInView: false,
        ),
      ),
    );
  }
}
