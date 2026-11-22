import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cover_view.dart';
import '../../app/library_providers.dart';
import '../../app/providers.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/cover_image.dart';
import '../../components/hold_row.dart';
import '../../components/hover_mark.dart';
import '../../components/motion.dart';
import '../../components/one_line_text.dart';
import '../../components/peek_row.dart';
import '../../components/status_menu_entries.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/watch_order.dart';
import '../../library/earlier_titles.dart';
import '../../library/entry_status.dart';
import '../../library/row_labels.dart';
import '../library/row_tap_area.dart';
import 'detail_block.dart';
import 'watch_order_rail.dart';

/// "3 of 5 on your list · 59 of 87 episodes watched".
String watchOrderSummary(WatchOrder order) {
  final total = order.episodesTotal;
  return '${order.onList} of ${order.rows.length} on your list'
      '${total > 0 ? ' · ${order.episodesWatched} of $total episodes watched' : ''}';
}

/// The state in words, for a screen reader: the square has no text.
String watchOrderStateLabel(WatchOrderRow row) {
  if (row.isLoadingDetails) return 'Loading details';
  final status = row.status;
  if (status != null) return status.label;
  return row.isNotAired ? 'Not aired yet' : 'Not on your list';
}

/// The line under a title's name: the status in words with its episodes, live
/// ones in teal. A finished title says only its episodes.
(String, bool) watchOrderState(WatchOrderRow row) {
  if (row.isLoadingDetails) return ('', false);
  final status = row.status;
  final total = row.episodes;
  final episodes = total == null ? null : '$total ep';
  String withEpisodes(String text) =>
      episodes == null ? text : '$text · $episodes';
  if (status == null) {
    return (
      row.isNotAired ? 'Not aired yet' : withEpisodes('Not on your list'),
      false,
    );
  }
  if (status == EntryStatus.completed) {
    return (episodes ?? status.label, false);
  }
  final live =
      status == EntryStatus.watching || status == EntryStatus.rewatching;
  final progress = episodeProgress(row.episodesWatched, total);
  // a title not started shows its total, not "0 / 12"
  if (progress.isNotEmpty && (live || row.episodesWatched > 0)) {
    return ('${status.label} $progress', live);
  }
  return (withEpisodes(status.label), false);
}

/// When the title came out: the year, or the whole date for a title still to
/// air.
String watchOrderWhen(WatchOrderRow row) {
  final date = row.startDate;
  if (row.isNotAired) return dateWords(date) ?? 'TBA';
  return date != null && date.length >= 4 ? date.substring(0, 4) : '';
}

/// "2018 · TV": when it came out and what it is.
String watchOrderMeta(WatchOrderRow row) {
  final type = row.mediaType;
  return [
    watchOrderWhen(row),
    if (type != null && type.isNotEmpty) typeName(type),
  ].where((part) => part.isNotEmpty).join(' · ');
}

/// The number row's height at the current text size, so every cover in the
/// strip starts at the same line and the arrows can centre on them.
double watchOrderMetaHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(Tokens.text2);

TextStyle _stateStyle(Color color) =>
    AppText.caption(color).copyWith(fontWeight: FontWeight.w700);

/// The gap between cards, which the line between the squares crosses.
const watchOrderGap = Tokens.space3;

/// The narrowest a card can be: as wide as the longest line it may hold, a
/// four digit episode count or a number, date and type, at the current text
/// size.
double watchOrderCardMinWidth(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  double widthOf(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  final state = _stateStyle(Tokens.ink);
  final widest = [
    for (final status in EntryStatus.values) ...[
      widthOf('${status.label} 1100 / 1100', state),
      widthOf('${status.label} · 1100 ep', state),
    ],
    widthOf('Not on your list · 1100 ep', state),
    widthOf('100', AppText.label(Tokens.ink, bold: true)) +
        Tokens.space2 +
        widthOf('30 Sep 2026 · TV Special', AppText.caption(Tokens.ink)),
  ].reduce(math.max);
  return math.max(Tokens.peekItemMinWidth, widest.ceilToDouble());
}

/// Where the arrows sit, from the item width, so they centre on the covers.
double watchOrderArrowTop(BuildContext context, double width) =>
    watchOrderMetaHeight(context) +
    Tokens.railLaneHeight +
    Tokens.space2 +
    (CoverImage.heightFor(width) - Tokens.controlHeight) / 2;

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
      count: rows.length == 1 ? '1 title' : '${rows.length} titles',
      aside: SectionNote(watchOrderSummary(order)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeekRow(
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
        ],
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
    if (row.isLoadingDetails) ref.watch(detailOnScreenProvider(row.malId));
    final entryId = row.entryId;
    return AppPopover(
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
              onPick: (status) => close(() => setOrAdd(ref, row, status)),
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

/// Sets the status of a watch order title on the list, or adds it with that
/// status.
void setOrAdd(WidgetRef ref, WatchOrderRow row, EntryStatus status) {
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

/// One title of the watch order: its release number, date and type, its stop
/// on the line, then its cover, name and its state in words. Every cover is
/// grey and dimmed until [lit], except the open title's, which stays in colour.
class WatchOrderCard extends StatelessWidget {
  const WatchOrderCard({
    super.key,
    required this.row,
    required this.width,
    required this.number,
    this.hasNext = false,
    this.travelled = false,
    this.lit = false,
  });

  final WatchOrderRow row;
  final double width;

  /// Its place in release order, from 1.
  final int number;

  /// Whether the line runs on to another card, and whether that part of it
  /// is behind you.
  final bool hasNext;
  final bool travelled;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final (state, live) = watchOrderState(row);
    final status = row.status;
    final total = row.episodes ?? 0;
    return HoverMark(
      on: lit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: watchOrderMetaHeight(context),
            child: Row(
              children: [
                Text(
                  '$number',
                  style: AppText.label(
                    row.isOpenTitle ? Tokens.ink : Tokens.inkSoft,
                    bold: true,
                  ),
                ),
                const SizedBox(width: Tokens.space2),
                Expanded(
                  child: OneLineText(
                    watchOrderMeta(row),
                    style: AppText.caption(Tokens.inkMuted),
                  ),
                ),
              ],
            ),
          ),
          WatchOrderRail(
            status: row.isLoadingDetails ? null : status,
            label: watchOrderStateLabel(row),
            share: total > 0 ? math.min(1.0, row.episodesSeen / total) : 0,
            travelled: travelled,
            reachToNext: hasNext ? width + watchOrderGap : null,
          ),
          const SizedBox(height: Tokens.space2),
          _Faded(
            on: !row.isOpenTitle && !lit,
            child: CoverView(
              malId: row.malId,
              width: width,
              loading: row.isLoadingDetails,
            ),
          ),
          const SizedBox(height: Tokens.space2),
          Text(
            row.name.isEmpty ? 'Loading details' : row.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              row.name.isEmpty
                  ? Tokens.inkMuted
                  : (status == EntryStatus.completed
                        ? Tokens.inkSoft
                        : Tokens.ink),
              bold: true,
            ).copyWith(height: Tokens.lineHeightWrapped),
          ),
          const SizedBox(height: Tokens.space1),
          OneLineText(
            state,
            style: _stateStyle(live ? Tokens.ink : Tokens.inkMuted),
          ),
          const SizedBox(height: Tokens.space2),
        ],
      ),
    );
  }
}

/// A picture with its colour taken out and dimmed to half while [on], easing
/// back to full colour when it turns off.
class _Faded extends StatelessWidget {
  const _Faded({required this.on, required this.child});

  final bool on;
  final Widget child;

  // the share of each channel in a grey of the same lightness
  static const _r = 0.2126;
  static const _g = 0.7152;
  static const _b = 0.0722;
  static const _dim = 0.5;

  static List<double> _matrix(double t) {
    double mix(double from, double to) => from + (to - from) * t;
    List<double> channel(int index) {
      final keep = [0.0, 0.0, 0.0]..[index] = 1.0;
      return [
        mix(keep[0], _r * _dim),
        mix(keep[1], _g * _dim),
        mix(keep[2], _b * _dim),
        0,
        0,
      ];
    }

    return [...channel(0), ...channel(1), ...channel(2), 0, 0, 0, 1, 0];
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: on ? 1 : 0),
      duration: chooseMotionDuration(context, Tokens.motionQuick),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => t == 0
          ? child!
          : ColorFiltered(
              colorFilter: ColorFilter.matrix(_matrix(t)),
              child: child,
            ),
    );
  }
}
