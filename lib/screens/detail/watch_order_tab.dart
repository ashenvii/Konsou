import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/providers.dart';
import '../../components/app_menu.dart';
import '../../components/hold_row.dart';
import '../../components/app_popover.dart';
import '../../components/status_menu_entries.dart';
import '../../detail/watch_order.dart';
import '../../library/earlier_titles.dart';
import '../../library/entry_status.dart';
import 'watch_order_row.dart';

/// The Watch order tab: the summary, then every title of the franchise. A
/// click opens that title's page; a right click opens the status menu, which
/// adds a title that is not on the list.
class WatchOrderTab extends StatelessWidget {
  const WatchOrderTab({super.key, required this.order, required this.onOpen});

  final WatchOrder order;
  final ValueChanged<WatchOrderRow> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WatchOrderSummary(order),
        for (final row in order.rows)
          _OrderRow(
            key: ValueKey(row.malId),
            row: row,
            onOpen: () => onOpen(row),
          ),
      ],
    );
  }
}

class _OrderRow extends ConsumerWidget {
  const _OrderRow({super.key, required this.row, required this.onOpen});

  final WatchOrderRow row;
  final VoidCallback onOpen;

  void _pick(WidgetRef ref, EntryStatus status) {
    final actions = ref.read(entryActionsProvider);
    final entryId = row.entryId;
    if (entryId != null) {
      actions.setStatus(entryId, status);
      return;
    }
    actions.add(
      EarlierTitle(
        malId: row.malId,
        name: row.name,
        isExtra: row.isExtra,
        mediaType: row.mediaType,
        startDate: row.startDate,
        episodes: row.episodes,
      ),
      status,
      airing: row.isNotAired ? 'not_yet_aired' : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // a title the scan found but has not fetched is fetched while it shows
    if (row.isLoadingDetails) ref.watch(detailOnScreenProvider(row.malId));
    final entryId = row.entryId;
    return AppPopover(
      builder: (context, handle) => WatchOrderRowView(
        row: row,
        // the open title is this page
        onOpen: row.isOpenTitle ? () {} : onOpen,
        onContextMenu: handle.openAt,
      ),
      popoverBuilder: (context, handle) {
        void close(VoidCallback action) {
          action();
          handle.close();
        }

        final actions = ref.read(entryActionsProvider);
        return AppMenu(
          entries: [
            ...statusMenuEntries(
              current: row.status,
              onPick: (status) => close(() => _pick(ref, status)),
            ),
            if (!row.isOpenTitle)
              MenuEntry(
                label: 'Open details',
                dividerAbove: true,
                onPressed: () => close(onOpen),
              ),
            if (entryId != null)
              MenuEntry(
                label: holdToRemoveLabel,
                destructive: true,
                hold: true,
                dividerAbove: true,
                holdHint: holdToRemoveHint,
                onPressed: () => close(() => actions.remove([entryId])),
              ),
          ],
        );
      },
    );
  }
}
