import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../app/entry_actions.dart';
import '../../app/library_providers.dart';
import '../../components/app_popover.dart';
import '../../components/cover_image.dart';
import '../../components/page_dim.dart';
import '../../components/popover_placement.dart';
import '../../design/tokens.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';
import 'card_details.dart';
import 'edit_entry.dart';
import 'list_columns.dart';
import 'quick_panel.dart';
import 'row_marker.dart';

/// Opens a title's quick panel against the card or row [context] draws: in
/// the grid beside the cover (`placeBesideCover`), in the list under the row
/// with its left edge on the name column, above it with no room under. Never
/// where the pointer was.
void openQuickPanel(
  BuildContext context,
  PopoverHandle handle, {
  required bool grid,
}) {
  final box = context.findRenderObject()! as RenderBox;
  final item = box.localToGlobal(Offset.zero) & box.size;
  if (grid) {
    final cover =
        item.topLeft & Size(item.width, CoverImage.heightFor(item.width));
    handle.openOver(cover, lift: item);
  } else {
    handle.openOver(
      Rect.fromLTRB(
        item.left + ListColumns.lead,
        item.top,
        item.right,
        item.bottom,
      ),
      lift: item,
    );
  }
}

/// A Library card or row with its quick panel. While the panel is open the
/// page under it is dimmed, as under Quick search, and the card or row is
/// drawn again above the dim in full colour, so only it and the panel stand
/// out.
class LibraryRowMenu extends StatelessWidget {
  const LibraryRowMenu({
    super.key,
    required this.row,
    required this.onOpen,
    required this.grid,
    required this.builder,
  });

  final LibraryRow row;
  final ValueChanged<LibraryRow> onOpen;

  /// A grid card; else a list row.
  final bool grid;
  final Widget Function(BuildContext context, PopoverHandle handle) builder;

  @override
  Widget build(BuildContext context) {
    return AppPopover(
      key: ValueKey(row.entryId),
      gap: grid ? Tokens.besideGap : Tokens.space1,
      place: grid ? placeBesideCover : placePopover,
      backdrop: (context, handle, lift) => Stack(
        children: [
          Positioned.fill(
            child: PageDim(onClose: handle.close, closeOnWheel: true),
          ),
          // the same card or row, above the dim; a click on it closes too
          Positioned.fromRect(
            rect: lift,
            child: IgnorePointer(child: builder(context, handle)),
          ),
        ],
      ),
      builder: (context, handle) => RowMarker(
        entryId: row.entryId,
        openMenu: () => openQuickPanel(context, handle, grid: grid),
        child: builder(context, handle),
      ),
      popoverBuilder: (context, handle) => _OpenMark(
        child: QuickPanel(
          row: row,
          details: _Details(row),
          onClose: handle.close,
          onStatus: (status) => editLibraryRow(
            context,
            row,
            (actions) => actions.setStatus(row.entryId, status),
          ),
          onOpen: () => onOpen(row),
          onRemove: () => editLibraryRow(
            context,
            row,
            (actions) => actions.remove(row.entryIds),
            keepInView: false,
          ),
        ),
      ),
    );
  }
}

/// Runs an edit on a row from the list, keeping the row in view unless told
/// not to.
Future<void> editLibraryRow(
  BuildContext context,
  LibraryRow row,
  Future<Object?> Function(EntryActions actions) action, {
  bool keepInView = true,
}) => editEntry(
  ProviderScope.containerOf(context).read,
  row.entryId,
  action,
  keepInView: keepInView,
);

/// The quick panel's top: the title's details, fetched in the page lane while
/// the panel is open; a title with no MAL page has its saved name and says it
/// is not linked.
class _Details extends ConsumerWidget {
  const _Details(this.row);

  final LibraryRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final malId = row.malId;
    final page = malId == null
        ? null
        : ref.watch(detailPageProvider(malId, entryId: row.entryId)).value;
    return CardDetails(
      name: row.name,
      details: page?.details,
      fetch: malId == null
          ? DetailFetch.idle
          : page?.fetch ?? DetailFetch.running,
      malScore: row.malScore,
      scorePending: row.isScorePending,
      notLinked: row.isNotLinked,
      progress: formatPanelProgress(row),
      trailingRoom: QuickPanel.cornerRoom,
    );
  }
}

/// Tells the Library a quick panel is open, for as long as this is shown.
class _OpenMark extends ConsumerStatefulWidget {
  const _OpenMark({required this.child});

  final Widget child;

  @override
  ConsumerState<_OpenMark> createState() => _OpenMarkState();
}

class _OpenMarkState extends ConsumerState<_OpenMark> {
  late final LibraryPanelOpen _open;

  @override
  void initState() {
    super.initState();
    _open = ref.read(libraryPanelOpenProvider.notifier);
    // a provider may not change while the tree builds
    SchedulerBinding.instance.addPostFrameCallback((_) => _open.opened());
  }

  @override
  void dispose() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _open.closed());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
