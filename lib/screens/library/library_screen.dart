import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/app_tab.dart';
import '../../components/cover_image.dart';
import '../../components/icon_square_button.dart';
import '../../components/more_button.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';
import '../../library/entry_edits.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/library_view.dart';
import 'entry_menu.dart';
import 'grid_layout.dart';
import 'library_grid_card.dart';
import 'library_list_row.dart';

/// The tabs in the row; the rest sit under More.
const _mainTabs = [
  LibraryTab.all,
  LibraryTab.watching,
  LibraryTab.planned,
  LibraryTab.completed,
];

const _moreTabs = [
  LibraryTab.onHold,
  LibraryTab.dropped,
  LibraryTab.notInterested,
];

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
  LibrarySort.title => 'Title',
  LibrarySort.score => 'Score',
  LibrarySort.added => 'Added',
};

/// The Library: tabs with counts, sort, grid or list, and the menu of each
/// row. [onDiscover] is the button of an empty library; [onOpen] opens an
/// entry's details.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({
    super.key,
    required this.onDiscover,
    required this.onOpen,
  });

  final VoidCallback onDiscover;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(libraryRowsProvider);
    final tab = ref.watch(libraryTabChoiceProvider);
    final sort = ref.watch(librarySortChoiceProvider);
    final layout =
        ref.watch(libraryLayoutChoiceProvider).value ?? LibraryLayout.grid;
    // keeps showing the old rows while a reload runs
    final all = loaded.value;
    final counts = all == null ? null : countTabs(all);
    return Padding(
      padding: const EdgeInsets.all(Tokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Library',
            style: TextStyle(
              fontFamily: Tokens.sans,
              fontWeight: FontWeight.w700,
              fontSize: Tokens.text5,
              color: Tokens.ink,
            ),
          ),
          const SizedBox(height: Tokens.space4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: Tokens.space3,
            children: [
              _Tabs(
                selected: tab,
                counts: counts,
                onSelect: ref.read(libraryTabChoiceProvider.notifier).select,
              ),
              _Controls(
                sort: sort,
                layout: layout,
                onSort: ref.read(librarySortChoiceProvider.notifier).select,
                onLayout: ref.read(libraryLayoutChoiceProvider.notifier).select,
              ),
            ],
          ),
          const SizedBox(height: Tokens.space4),
          Expanded(
            child: all == null
                ? (loaded.hasError
                      ? const _Message('Your library could not be read.')
                      : const _Skeleton())
                : _Rows(
                    rows: sortRows(rowsInTab(all, tab), sort),
                    libraryIsEmpty: all.isEmpty,
                    showStatus: tab == LibraryTab.all,
                    layout: layout,
                    onDiscover: onDiscover,
                    onOpen: onOpen,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  final LibraryTab selected;
  final Map<LibraryTab, int>? counts;
  final ValueChanged<LibraryTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final inMore = _moreTabs.contains(selected);
    return Wrap(
      children: [
        for (final tab in _mainTabs)
          AppTab(
            label: _tabLabel(tab),
            selected: tab == selected,
            count: counts?[tab],
            onPressed: () => onSelect(tab),
          ),
        AppPopover(
          builder: (context, handle) => AppTab(
            label: inMore ? _tabLabel(selected) : 'More',
            selected: inMore,
            count: inMore ? (counts ?? const {})[selected] : null,
            opensMenu: true,
            onPressed: handle.open,
          ),
          popoverBuilder: (context, handle) => AppMenu(
            entries: [
              for (final tab in _moreTabs)
                MenuEntry(
                  label: '${_tabLabel(tab)}  ${counts?[tab] ?? 0}',
                  selected: tab == selected,
                  onPressed: () {
                    onSelect(tab);
                    handle.close();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.sort,
    required this.layout,
    required this.onSort,
    required this.onLayout,
  });

  final LibrarySort sort;
  final LibraryLayout layout;
  final ValueChanged<LibrarySort> onSort;
  final ValueChanged<LibraryLayout> onLayout;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPopover(
          builder: (context, handle) => AppButton(
            label: _sortLabel(sort),
            kind: ButtonKind.secondary,
            opensMenu: true,
            onPressed: handle.open,
          ),
          popoverBuilder: (context, handle) => AppMenu(
            entries: [
              for (final choice in LibrarySort.values)
                MenuEntry(
                  label: _sortLabel(choice),
                  selected: choice == sort,
                  onPressed: () {
                    onSort(choice);
                    handle.close();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(width: Tokens.space3),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Tokens.space5),
        Text(text, style: AppText.label(Tokens.inkSoft)),
        if (action != null) ...[const SizedBox(height: Tokens.space4), action!],
      ],
    );
  }
}

/// Blank covers in the grid's shape while the first read runs.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = GridLayout.forWidth(constraints.maxWidth);
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: _delegate(layout),
          itemCount: layout.columns * 2,
          itemBuilder: (context, index) => CoverImage(width: layout.cardWidth),
        );
      },
    );
  }
}

SliverGridDelegate _delegate(GridLayout layout) =>
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: layout.columns,
      mainAxisSpacing: GridLayout.gap,
      crossAxisSpacing: GridLayout.gap,
      mainAxisExtent: layout.cardHeight,
    );

class _Rows extends StatelessWidget {
  const _Rows({
    required this.rows,
    required this.libraryIsEmpty,
    required this.showStatus,
    required this.layout,
    required this.onDiscover,
    required this.onOpen,
  });

  final List<LibraryRow> rows;
  final bool libraryIsEmpty;
  final bool showStatus;
  final LibraryLayout layout;
  final VoidCallback onDiscover;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (libraryIsEmpty) {
      return _Message(
        'Your library is empty.',
        action: AppButton(label: 'Go to Discover', onPressed: onDiscover),
      );
    }
    if (rows.isEmpty) return const _Message('Nothing here.');

    if (layout == LibraryLayout.list) {
      return ListView.builder(
        itemExtent: Tokens.listRowHeight,
        itemCount: rows.length,
        itemBuilder: (context, index) => _RowMenu(
          row: rows[index],
          onOpen: onOpen,
          builder: (context, handle) => LibraryListRow(
            row: rows[index],
            showStatus: showStatus,
            onOpen: () => onOpen(rows[index].entryId),
            onCheck: (done) => _edit(
              context,
              (e) => done
                  ? e.setStatus(rows[index].entryId, EntryStatus.completed)
                  : e.uncheck(rows[index].entryId),
            ),
            onContextMenu: handle.openAt,
            menu: Builder(
              builder: (context) => MoreButton(
                onPressed: () {
                  // open the menu under the button, not under the row
                  final box = context.findRenderObject()! as RenderBox;
                  handle.openAt(box.localToGlobal(Offset(0, box.size.height)));
                },
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = GridLayout.forWidth(constraints.maxWidth);
        return GridView.builder(
          gridDelegate: _delegate(grid),
          itemCount: rows.length,
          itemBuilder: (context, index) => _RowMenu(
            row: rows[index],
            onOpen: onOpen,
            builder: (context, handle) => LibraryGridCard(
              row: rows[index],
              showStatus: showStatus,
              onOpen: () => onOpen(rows[index].entryId),
              onContextMenu: handle.openAt,
            ),
          ),
        );
      },
    );
  }
}

/// Runs an edit, then reloads the rows so the change shows at once. The result
/// (an episode that has not aired, say) is not told to the user yet: that
/// waits for the toast.
Future<void> _edit(
  BuildContext context,
  Future<Object?> Function(EntryEdits edits) action,
) async {
  final scope = ProviderScope.containerOf(context);
  await action(scope.read(entryEditsProvider));
  scope.invalidate(libraryRowsProvider);
}

/// The popover that holds one row's menu, with the actions wired to the
/// edits. [builder] draws the row and opens the menu through the handle.
class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.row,
    required this.onOpen,
    required this.builder,
  });

  final LibraryRow row;
  final ValueChanged<String> onOpen;
  final Widget Function(BuildContext context, PopoverHandle handle) builder;

  @override
  Widget build(BuildContext context) {
    return AppPopover(
      key: ValueKey(row.entryId),
      builder: builder,
      popoverBuilder: (context, handle) => EntryMenu(
        row: row,
        onClose: handle.close,
        onStatus: (status) =>
            _edit(context, (e) => e.setStatus(row.entryId, status)),
        onAddEpisode: () => _edit(context, (e) => e.addEpisode(row.entryId)),
        onRewatch: () => _edit(context, (e) => e.rewatch(row.entryId)),
        onOpen: () => onOpen(row.entryId),
        onRemove: () => _edit(context, (e) => e.remove(row.entryIds)),
      ),
    );
  }
}
