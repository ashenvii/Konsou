import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/providers.dart';
import '../../app/score_fill.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/hold_row.dart';
import '../../components/peek_row.dart';
import '../../components/status_menu_entries.dart';
import '../../detail/watch_order.dart';
import '../../detail/watch_order_words.dart';
import '../../library/count_format.dart';
import '../../library/earlier_titles.dart';
import '../library/row_tap_area.dart';
import 'detail_section.dart';
import 'section_note.dart';
import 'watch_order_card.dart';

/// The watch order: its summary, then every title of the franchise as a
/// cover in a peeking row, on a line that runs through their state squares. A
/// click opens that title's page; a right click opens the status menu, which
/// adds a title that is not on the list.
class WatchOrderSection extends StatelessWidget {
  const WatchOrderSection({
    super.key,
    required this.order,
    required this.onOpen,
  });

  final WatchOrder order;
  final ValueChanged<WatchOrderRow> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = order.rows;
    final open = rows.indexWhere((row) => row.isOpenTitle);
    return DetailSection(
      title: 'Watch order',
      count: formatCountOf(rows.length, 'title'),
      aside: SectionNote(watchOrderSummary(order)),
      child: PeekRow(
        count: rows.length,
        gap: watchOrderGap,
        startAt: math.max(0, open),
        minItemWidth: watchOrderCardMinWidth(context),
        arrowTop: (width) => watchOrderArrowTop(context, width),
        itemBuilder: (context, i, width) => _OrderItem(
          key: ValueKey(rows[i].malId),
          row: rows[i],
          onOpen: () => onOpen(rows[i]),
          cardFor: (lit) => WatchOrderCard(
            row: rows[i],
            width: width,
            number: i + 1,
            hasNext: i < rows.length - 1,
            travelled: i < open,
            lit: lit,
          ),
        ),
      ),
    );
  }
}

/// A watch order title wired to the list: the status menu on a right click,
/// fetched while it shows when the scan found it but has not read it yet.
class _OrderItem extends ConsumerWidget {
  const _OrderItem({
    super.key,
    required this.row,
    required this.onOpen,
    required this.cardFor,
  });

  final WatchOrderRow row;
  final VoidCallback onOpen;

  /// The card, lit or not.
  final WatchOrderCard Function(bool lit) cardFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (row.isLoadingDetails) {
      ref.watch(detailOnScreenProvider(row.malId, lane: Lane.page));
    }
    final entryId = row.entryId;
    return ScoreFill(
      malId: row.malId,
      pending: row.isScorePending,
      child: AppPopover(
        builder: (context, handle) => RowTapArea(
          // the open title is this page
          onOpen: row.isOpenTitle ? () {} : onOpen,
          onContextMenu: handle.openAt,
          builder: (context, state) =>
              cardFor(state.hovered || state.focused || handle.isOpen),
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
                onPick: (status) => close(
                  () => ref
                      .read(entryActionsProvider)
                      .setOrAdd(
                        EarlierTitle(
                          malId: row.malId,
                          entryId: row.entryId,
                          name: row.name,
                          isExtra: row.isExtra,
                          mediaType: row.mediaType,
                          startDate: row.startDate,
                          episodes: row.episodes,
                        ),
                        status,
                        airing: row.isNotAired ? 'not_yet_aired' : null,
                      ),
                ),
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
      ),
    );
  }
}
