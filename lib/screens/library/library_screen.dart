import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/cover_image.dart';
import '../../components/icon_square_button.dart';
import '../../components/more_button.dart';
import '../../components/page_frame.dart';
import '../../components/page_title.dart';
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

/// The Library: a top row with the status switcher, the grid or list switch
/// and the sort, then the rows, each with its menu. [onDiscover] is the
/// button of an empty library; [onOpen] opens an entry's details.
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
    final kept = ref.watch(libraryKeptProvider);
    final layout =
        ref.watch(libraryLayoutChoiceProvider).value ?? LibraryLayout.grid;
    // keeps showing the old rows while a reload runs
    final all = loaded.value;
    final counts = all == null ? null : countTabs(all);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: PageFrame.top,
          // one line, everything centred on it: the heading and its status
          // switcher on the left, the layout switch in the middle, the sort
          // on the right
          child: Row(
            children: [
              Expanded(
                // a window narrower than the minimum shrinks the heading a
                // little instead of overflowing
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PageTitle('Library'),
                      const SizedBox(width: Tokens.space4),
                      _StatusSwitcher(
                        selected: tab,
                        counts: counts,
                        onSelect: ref
                            .read(libraryTabChoiceProvider.notifier)
                            .select,
                      ),
                    ],
                  ),
                ),
              ),
              _LayoutSwitch(
                layout: layout,
                onLayout: ref.read(libraryLayoutChoiceProvider.notifier).select,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _SortButton(
                    sort: sort,
                    onSort: ref.read(librarySortChoiceProvider.notifier).select,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: all == null
              ? (loaded.hasError
                    ? const _Message('Your library could not be read.')
                    : const _Skeleton())
              : _Rows(
                  rows: sortRows(rowsInTab(all, tab, keep: kept), sort),
                  keptIds: kept,
                  libraryIsEmpty: all.isEmpty,
                  showStatus: tab == LibraryTab.all,
                  layout: layout,
                  onDiscover: onDiscover,
                  onOpen: onOpen,
                ),
        ),
      ],
    );
  }
}

/// The status the Library shows, with its count. Works like the sort button:
/// a click opens the menu of every status and its count right under it.
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
    return _ChoiceButton(
      label: _tabLabel(selected),
      count: counts?[selected],
      choices: [
        for (final tab in LibraryTab.values)
          (
            label: '${_tabLabel(tab)}  ${counts?[tab] ?? 0}',
            selected: tab == selected,
            pick: () => onSelect(tab),
          ),
      ],
    );
  }
}

/// A secondary button that opens a menu of choices under itself. The status
/// switcher and the sort are both one of these.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.choices, this.count});

  final String label;
  final int? count;
  final List<({String label, bool selected, VoidCallback pick})> choices;

  @override
  Widget build(BuildContext context) {
    return AppPopover(
      builder: (context, handle) => AppButton(
        label: label,
        kind: ButtonKind.secondary,
        opensMenu: true,
        count: count,
        onPressed: handle.open,
      ),
      popoverBuilder: (context, handle) => AppMenu(
        entries: [
          for (final choice in choices)
            MenuEntry(
              label: choice.label,
              selected: choice.selected,
              onPressed: () {
                choice.pick();
                handle.close();
              },
            ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSort});

  final LibrarySort sort;
  final ValueChanged<LibrarySort> onSort;

  @override
  Widget build(BuildContext context) {
    return _ChoiceButton(
      label: _sortLabel(sort),
      choices: [
        for (final choice in LibrarySort.values)
          (
            label: _sortLabel(choice),
            selected: choice == sort,
            pick: () => onSort(choice),
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

/// The grid at the page's width: its layout and the view that draws it. The
/// rows and the loading skeleton both use it.
Widget _grid({
  required int Function(GridLayout layout) itemCount,
  required Widget Function(GridLayout layout, int index) itemBuilder,
  ScrollPhysics? physics,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final layout = GridLayout.forWidth(
        constraints.maxWidth - PageFrame.content.horizontal,
      );
      return GridView.builder(
        padding: PageFrame.content,
        physics: physics,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.columns,
          mainAxisSpacing: GridLayout.gap,
          crossAxisSpacing: GridLayout.gap,
          mainAxisExtent: layout.cardHeight,
        ),
        itemCount: itemCount(layout),
        itemBuilder: (context, index) => itemBuilder(layout, index),
      );
    },
  );
}

/// Blank covers in the grid's shape while the first read runs.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => _grid(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: (layout) => layout.columns * 2,
    itemBuilder: (layout, index) => CoverImage(width: layout.cardWidth),
  );
}

class _Rows extends StatelessWidget {
  const _Rows({
    required this.rows,
    required this.libraryIsEmpty,
    required this.showStatus,
    required this.keptIds,
    required this.layout,
    required this.onDiscover,
    required this.onOpen,
  });

  final List<LibraryRow> rows;

  /// Rows an edit moved out of this status; they show their status so the
  /// change can be seen.
  final Set<String> keptIds;
  final bool libraryIsEmpty;
  final bool showStatus;
  final LibraryLayout layout;
  final VoidCallback onDiscover;
  final ValueChanged<String> onOpen;

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
    if (rows.isEmpty) return const _Message('Nothing here.');

    if (layout == LibraryLayout.grid) {
      return _grid(
        itemCount: (_) => rows.length,
        itemBuilder: (_, index) => _RowMenu(
          row: rows[index],
          onOpen: onOpen,
          builder: (context, handle) => LibraryGridCard(
            row: rows[index],
            showStatus: _statusShown(rows[index]),
            onOpen: () => onOpen(rows[index].entryId),
            onContextMenu: handle.openAt,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: PageFrame.content,
      itemExtent: Tokens.listRowHeight,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return _RowMenu(
          row: row,
          onOpen: onOpen,
          builder: (context, handle) => LibraryListRow(
            row: row,
            showStatus: _statusShown(row),
            onOpen: () => onOpen(row.entryId),
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
                  handle.openAt(box.localToGlobal(Offset(0, box.size.height)));
                },
              ),
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
  LibraryRow row,
  Future<Object?> Function(EntryEdits edits) action, {
  bool keepInView = true,
}) async {
  final scope = ProviderScope.containerOf(context);
  await action(scope.read(entryEditsProvider));
  // the row stays where it is, showing its new status, until the tab changes
  if (keepInView) scope.read(libraryKeptProvider.notifier).keep(row.entryId);
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
            _edit(context, row, (e) => e.setStatus(row.entryId, status)),
        onAddEpisode: () =>
            _edit(context, row, (e) => e.addEpisode(row.entryId)),
        onRewatch: () => _edit(context, row, (e) => e.rewatch(row.entryId)),
        onOpen: () => onOpen(row.entryId),
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
