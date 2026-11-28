import '../../components/measure_text.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../components/cover_well.dart';
import '../../components/one_line_text.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/watch_order.dart';
import '../../detail/watch_order_words.dart';
import '../../library/entry_status.dart';
import '../../library/row_labels.dart';
import 'strip_card.dart';
import 'watch_order_rail.dart';

/// One title of the watch order: its release number with its type and year,
/// its stop on the line, then the strip card. Every cover is grey and dimmed
/// until [lit], except the open title's, which stays in colour.
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
    final status = row.status;
    final total = row.episodes ?? 0;
    final type = row.mediaType;
    final caption = AppText.caption(Tokens.inkMuted);
    return StripCard(
      title: row,
      width: width,
      state: row.isLoadingDetails ? '' : watchOrderStateLabel(row),
      stateInk: row.isOpenTitle ? Tokens.ink : Tokens.inkMuted,
      nameInk: status == EntryStatus.completed ? Tokens.inkSoft : Tokens.ink,
      faded: !row.isOpenTitle && !lit,
      open: row.isOpenTitle,
      isExtra: row.isExtra,
      lit: lit,
      top: Column(
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
                    type == null || type.isEmpty ? '' : formatType(type),
                    style: caption,
                  ),
                ),
                const SizedBox(width: Tokens.space2),
                Text(
                  formatCardWhen(row.startDate, notAired: row.isNotAired),
                  style: caption,
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
        ],
      ),
    );
  }
}

/// The gap between cards, which the line between the squares crosses.
const watchOrderGap = Tokens.space3;

/// The number row's height at the current text size, so every cover in the
/// strip starts at the same line and the arrows can centre on them.
double watchOrderMetaHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(Tokens.text2);

/// The narrowest a card can be: as wide as the longest line it may hold, a
/// state word, a number with its type and date, or a four digit footer count,
/// at the current text size.
double watchOrderCardMinWidth(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  double widthOf(String text, TextStyle style) =>
      measureText(text, style, textScaler: scaler).width;

  final state = StripCard.stateStyle(Tokens.ink);
  final caption = AppText.caption(Tokens.ink);
  final widest = [
    for (final status in EntryStatus.values) widthOf(status.label, state),
    widthOf('Not on your list', state),
    widthOf('Not aired yet', state),
    widthOf('100', AppText.label(Tokens.ink, bold: true)) +
        Tokens.space2 * 2 +
        widthOf('TV Special', caption) +
        widthOf('30 Sep 2026', caption),
    CoverWell.inset +
        Tokens.space1 * 2 +
        widthOf('1100 / 1100', AppText.tally(Tokens.ink, size: Tokens.text1)),
  ].reduce(math.max);
  return math.max(Tokens.peekItemMinWidth, widest.ceilToDouble());
}

/// Where the arrows sit, from the item width, so they centre on the covers.
double watchOrderArrowTop(BuildContext context, double width) =>
    StripCard.arrowTop(
      width,
      above:
          watchOrderMetaHeight(context) + Tokens.railLaneHeight + Tokens.space2,
    );
