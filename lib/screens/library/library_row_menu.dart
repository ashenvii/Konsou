import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/entry_actions.dart';
import '../../components/app_popover.dart';
import '../../library/library_row.dart';
import 'edit_entry.dart';
import 'entry_menu.dart';
import 'row_marker.dart';

void openMenuBelow(BuildContext context, PopoverHandle handle) {
  final box = context.findRenderObject()! as RenderBox;
  handle.openAt(box.localToGlobal(Offset(0, box.size.height)));
}

class LibraryRowMenu extends StatelessWidget {
  const LibraryRowMenu({
    super.key,
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
        openMenu: () => openMenuBelow(context, handle),
        child: builder(context, handle),
      ),
      popoverBuilder: (context, handle) => EntryMenu(
        row: row,
        onClose: handle.close,
        onStatus: (status) => editLibraryRow(
          context,
          row,
          (actions) => actions.setStatus(row.entryId, status),
        ),
        onAddEpisode: () => editLibraryRow(
          context,
          row,
          (actions) => actions.addEpisode(row.entryId),
        ),
        onRewatch: () => editLibraryRow(
          context,
          row,
          (actions) => actions.rewatch(row.entryId),
        ),
        onOpen: () => onOpen(row),
        onRemove: () => editLibraryRow(
          context,
          row,
          (actions) => actions.remove(row.entryIds),
          keepInView: false,
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
