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

/// "3 of 5 on your list · 59 of 87 episodes watched".
String watchOrderSummary(WatchOrder order) {
  final total = order.episodesTotal;
  return '${order.onList} of ${order.rows.length} on your list'
      '${total > 0 ? ' · ${order.episodesWatched} of $total episodes watched' : ''}';
}

/// The title to watch after the open one: the first story title after it in
/// the order that is not finished. Extras are left out, since they are
/// optional; a row with no name yet cannot be shown.
WatchOrderRow? nextUp(WatchOrder order) {
  final rows = order.rows;
  final open = rows.indexWhere((row) => row.isOpenTitle);
  if (open < 0) return null;
  for (final row in rows.skip(open + 1)) {
    if (row.isExtra || row.name.isEmpty) continue;
    if (row.status == EntryStatus.completed) continue;
    return row;
  }
  return null;
}

/// The user's state on a title, under its name on the card, with the
/// episodes: "Watching 9 / 16" while it is under way, otherwise the status
/// or why there is none, then the episode count, "Completed · 25 ep".
(String, Color) watchOrderState(WatchOrderRow row) {
  final episodes = row.episodes == null ? null : '${row.episodes} ep';
  String withEpisodes(String text) =>
      episodes == null ? text : '$text · $episodes';
  if (row.isLoadingDetails) {
    return (row.name.isEmpty ? '' : 'Loading details', Tokens.inkMuted);
  }
  if (row.isNotAired) return (withEpisodes('Not aired yet'), Tokens.inkMuted);
  final status = row.status;
  if (status == null) {
    return (withEpisodes('Not on your list'), Tokens.inkMuted);
  }
  final live =
      status == EntryStatus.watching || status == EntryStatus.rewatching;
  final progress = episodeProgress(row.episodesWatched, row.episodes);
  if (status != EntryStatus.completed && progress.isNotEmpty) {
    return ('${status.label} $progress', live ? Tokens.mint : Tokens.inkSoft);
  }
  return (withEpisodes(status.label), live ? Tokens.mint : Tokens.inkSoft);
}

/// When the title came out, beside its type tag: the year, or the whole date
/// for a title still to air.
String watchOrderWhen(WatchOrderRow row) {
  final date = row.startDate;
  if (row.isNotAired) return dateWords(date) ?? 'TBA';
  return date != null && date.length >= 4 ? date.substring(0, 4) : '';
}

/// The type tag's height at the current text size, so every cover in the
/// strip starts at the same line and the arrows can centre on them.
double typeTagHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(Tokens.text1) + 2 * Tokens.space1;

TextStyle _stateStyle(Color color) =>
    AppText.caption(color).copyWith(fontWeight: FontWeight.w700);

/// The narrowest a card can be: as wide as the longest line it may hold, a
/// four digit episode count included, at the current text size.
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
  final tag = _stateStyle(Tokens.ink);
  final when = AppText.caption(Tokens.ink);
  final widest = [
    for (final status in EntryStatus.values) ...[
      widthOf('${status.label} 1100 / 1100', state),
      widthOf('${status.label} · 1100 ep', state),
    ],
    widthOf('Not on your list · 1100 ep', state),
    widthOf('Not aired yet · 1100 ep', state),
    widthOf('TV Special', tag) +
        2 * Tokens.space2 +
        Tokens.space2 +
        widthOf('30 Sep 2026', when),
  ].reduce(math.max);
  return math.max(Tokens.peekItemMinWidth, widest.ceilToDouble());
}

/// The watch order: its summary, then every title of the franchise as a
/// cover in a peeking row. A click opens that title's page; a right click
/// opens the status menu, which adds a title that is not on the list.
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
    final next = nextUp(order);
    return DetailBlock(
      title: 'Watch order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(watchOrderSummary(order), style: AppText.label(Tokens.inkSoft)),
          const SizedBox(height: Tokens.space3),
          PeekRow(
            count: rows.length,
            minItemWidth: watchOrderCardMinWidth(context),
            arrowTop: (width) =>
                typeTagHeight(context) +
                Tokens.space2 +
                (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
            itemBuilder: (context, i, width) => _OrderItem(
              key: ValueKey(rows[i].malId),
              row: rows[i],
              width: width,
              isNext: identical(rows[i], next),
              onOpen: () => onOpen(rows[i]),
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
    required this.width,
    required this.isNext,
    required this.onOpen,
  });

  final WatchOrderRow row;
  final double width;
  final bool isNext;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (row.isLoadingDetails) ref.watch(detailOnScreenProvider(row.malId));
    final entryId = row.entryId;
    return AppPopover(
      builder: (context, handle) => RowTapArea(
        // the open title is this page
        onOpen: row.isOpenTitle ? () {} : onOpen,
        onContextMenu: handle.openAt,
        builder: (context, state) => WatchOrderCard(
          row: row,
          width: width,
          isNext: isNext,
          lit: state.hovered || state.focused || handle.isOpen,
        ),
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

/// One title of the watch order: its cover, then the user's state on it, a
/// progress line, the title and its type, year and episodes. A finished title
/// has no colour and is dimmed until [lit]. The open title is outlined in
/// ink, the next one in amber.
class WatchOrderCard extends StatelessWidget {
  const WatchOrderCard({
    super.key,
    required this.row,
    required this.width,
    this.isNext = false,
    this.lit = false,
  });

  final WatchOrderRow row;
  final double width;
  final bool isNext;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final (state, stateColor) = watchOrderState(row);
    final outline = row.isOpenTitle
        ? Tokens.ink
        : (isNext ? Tokens.amber : null);
    final status = row.status;
    final seen = status == null || row.isLoadingDetails
        ? null
        : switch (row.episodes) {
            final total? when total > 0 => math.min(
              1.0,
              row.episodesSeen / total,
            ),
            _ => status == EntryStatus.completed ? 1.0 : null,
          };
    return HoverMark(
      on: lit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: typeTagHeight(context),
            child: Row(
              children: [
                TypeTag(row.mediaType, isExtra: row.isExtra),
                const SizedBox(width: Tokens.space2),
                Expanded(
                  child: OneLineText(
                    watchOrderWhen(row),
                    style: AppText.caption(Tokens.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Tokens.space2),
          Container(
            foregroundDecoration: outline == null
                ? null
                : BoxDecoration(
                    border: Border.all(color: outline, width: Tokens.focusRing),
                  ),
            child: _Faded(
              on: status == EntryStatus.completed && !lit,
              child: CoverView(
                malId: row.malId,
                width: width,
                loading: row.isLoadingDetails,
              ),
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
          OneLineText(state, style: _stateStyle(stateColor)),
          const SizedBox(height: Tokens.space2),
          _Progress(seen, live: stateColor == Tokens.mint),
          const SizedBox(height: Tokens.space2),
        ],
      ),
    );
  }
}

/// How much of a title is watched, as a thin line; nothing for a title not
/// on the list.
class _Progress extends StatelessWidget {
  const _Progress(this.share, {required this.live});

  final double? share;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final share = this.share;
    return SizedBox(
      height: Tokens.hoverEdge,
      child: share == null
          ? null
          : ColoredBox(
              color: Tokens.surface,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: share,
                child: ColoredBox(color: live ? Tokens.mint : Tokens.inkMuted),
              ),
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

/// The small type label over a cover: mint for TV and its seasons, amber for
/// movies, OVAs, specials and the rest.
class TypeTag extends StatelessWidget {
  const TypeTag(this.mediaType, {super.key, required this.isExtra});

  final String? mediaType;
  final bool isExtra;

  @override
  Widget build(BuildContext context) {
    final type = mediaType;
    final story = type == 'tv' && !isExtra;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.space2),
        alignment: Alignment.center,
        color: Tokens.surface,
        child: Text(
          type == null || type.isEmpty ? '?' : typeName(type),
          maxLines: 1,
          softWrap: false,
          style: AppText.caption(story ? Tokens.mint : Tokens.amber)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
