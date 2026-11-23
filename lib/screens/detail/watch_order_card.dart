import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../app/providers.dart';
import '../../components/cover_image.dart';
import '../../components/hover_mark.dart';
import '../../components/motion.dart';
import '../../components/one_line_text.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/watch_order.dart';
import '../../detail/watch_order_words.dart';
import '../../library/entry_status.dart';
import 'watch_order_rail.dart';

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
            child: DecoratedBox(
              // the open title is this page: its cover is lit
              position: DecorationPosition.foreground,
              decoration: row.isOpenTitle
                  ? BoxDecoration(
                      border: Border.all(
                        color: Tokens.pop,
                        width: Tokens.litEdge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Tokens.pop.withValues(alpha: 0.5),
                          blurRadius: Tokens.openGlow,
                        ),
                      ],
                    )
                  : const BoxDecoration(),
              child: CoverView(
                lane: Lane.page,
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

/// The gap between cards, which the line between the squares crosses.
const watchOrderGap = Tokens.space3;

/// The number row's height at the current text size, so every cover in the
/// strip starts at the same line and the arrows can centre on them.
double watchOrderMetaHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(Tokens.text2);

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

TextStyle _stateStyle(Color color) =>
    AppText.caption(color).copyWith(fontWeight: FontWeight.w700);

/// A picture with its colour taken out and dimmed to half while [on], easing
/// back to full colour when it turns off.
class _Faded extends StatelessWidget {
  const _Faded({required this.on, required this.child});

  final bool on;
  final Widget child;

  // the share of each channel in a grey of the same lightness
  static const _redShare = 0.2126;
  static const _greenShare = 0.7152;
  static const _blueShare = 0.0722;
  static const _dim = 0.5;

  static List<double> _matrix(double fade) {
    double mix(double from, double to) => from + (to - from) * fade;
    List<double> channel(int index) {
      final keep = [0.0, 0.0, 0.0]..[index] = 1.0;
      return [
        mix(keep[0], _redShare * _dim),
        mix(keep[1], _greenShare * _dim),
        mix(keep[2], _blueShare * _dim),
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
      // filtered even at no fade, so the cover is not remounted on every hover
      builder: (context, fade, child) => ColorFiltered(
        colorFilter: ColorFilter.matrix(_matrix(fade)),
        child: child,
      ),
    );
  }
}
