import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../app/providers.dart';
import '../../components/card_foot.dart';
import '../../components/card_name.dart';
import '../../components/cover_image.dart';
import '../../components/cover_well.dart';
import '../../components/faded.dart';
import '../../components/hover_mark.dart';
import '../../components/key_cap.dart';
import '../../components/mal_score_line.dart';
import '../../components/one_line_text.dart';
import '../../components/skeleton.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/strip_title.dart';

/// A [title] in a strip on Detail: an optional [top] (the watch order's number
/// line and rail), the cover in its well with the footer under it, the name
/// on two lines, MAL's score, then [state] in words. [faded] covers are grey
/// and dimmed; the [open] title's well is ringed in pop. An extra wears the
/// "Extra" key cap at the foot of its cover.
class StripCard extends StatelessWidget {
  const StripCard({
    super.key,
    required this.title,
    required this.width,
    required this.state,
    this.top,
    this.pictureUrl,
    this.stateInk = Tokens.inkMuted,
    this.nameInk = Tokens.ink,
    this.faded = false,
    this.open = false,
    this.isExtra = false,
    this.lit = false,
  });

  final StripTitle title;
  final double width;
  final String state;
  final Widget? top;
  final String? pictureUrl;
  final Color stateInk;
  final Color nameInk;
  final bool faded;
  final bool open;
  final bool isExtra;

  /// Hover or keyboard focus.
  final bool lit;

  /// From the card's top to the middle of its cover, less half an arrow, for
  /// a strip's arrows; [above] is the height of the [top].
  static double arrowTop(double width, {double above = 0}) =>
      above +
      Tokens.wellPad +
      (CoverImage.heightFor(width - CoverWell.inset) - Tokens.controlHeight) /
          2;

  static TextStyle stateStyle(Color color) =>
      AppText.caption(color).copyWith(fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final top = this.top;
    final loading = title.isLoadingDetails;
    return HoverMark(
      on: lit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?top,
          // the open title is this page: its well is ringed, the glow behind it
          DecoratedBox(
            decoration: open
                ? BoxDecoration(
                    borderRadius: Tokens.wellCorners,
                    boxShadow: [
                      BoxShadow(
                        color: Tokens.pop.withValues(alpha: 0.5),
                        blurRadius: Tokens.openGlow,
                      ),
                    ],
                  )
                : const BoxDecoration(),
            position: DecorationPosition.background,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: open
                  ? BoxDecoration(
                      borderRadius: Tokens.wellCorners,
                      border: Border.all(
                        color: Tokens.pop,
                        width: Tokens.litEdge,
                      ),
                    )
                  : const BoxDecoration(),
              child: CoverWell(
                // the state is the word under the name, so the footer is the count
                foot: CardFoot(count: title.count),
                child: Stack(
                  children: [
                    Faded(
                      on: faded,
                      child: CoverView(
                        lane: Lane.page,
                        malId: title.malId,
                        width: width - CoverWell.inset,
                        pictureUrl: pictureUrl,
                        loading: loading,
                      ),
                    ),
                    if (isExtra)
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: KeyCaps('Extra'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Tokens.space2),
          CardName(title.name, color: nameInk, loading: title.name.isEmpty),
          const SizedBox(height: Tokens.space1),
          if (loading || title.isScorePending)
            const FractionallySizedBox(
              widthFactor: 0.5,
              child: Skeleton(height: Tokens.text1),
            )
          else
            MalScoreLine(score: title.malScore),
          const SizedBox(height: Tokens.space1),
          OneLineText(state, style: stateStyle(stateInk)),
          const SizedBox(height: Tokens.space2),
        ],
      ),
    );
  }
}
