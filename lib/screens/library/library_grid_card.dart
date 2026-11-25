import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cover_view.dart';
import '../../app/detail_providers.dart';
import '../../components/card_foot.dart';
import '../../components/card_name.dart';
import '../../components/cover_image.dart';
import '../../components/cover_well.dart';
import '../../components/hover_details.dart';
import '../../components/key_cap.dart';
import '../../components/mal_score_line.dart';
import '../../components/motion.dart';
import '../../components/one_line_text.dart';
import '../../components/skeleton.dart';
import '../../components/touch_target.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';
import 'card_details.dart';
import 'row_tap_area.dart';

/// A Library title as a grid card: the cover in its well with the type tag on
/// it and the footer under it, the name on two lines, then MAL's score and
/// the year. Hover and keyboard focus light the well, lift the card and add
/// the status word to the footer; resting there opens the details popover
/// beside it (desktop only).
class LibraryGridCard extends StatelessWidget {
  const LibraryGridCard({
    super.key,
    required this.row,
    required this.showStatus,
    required this.onOpen,
    required this.onContextMenu,
  });

  final LibraryRow row;

  /// A tab that mixes statuses, so the footer shows the status mark.
  final bool showStatus;
  final VoidCallback onOpen;

  final ValueChanged<Offset> onContextMenu;

  /// The height a card of [width] takes: the well with the cover and the
  /// footer, the name's two lines, the score line.
  static double heightFor(double width, TextScaler textScaler) =>
      Tokens.wellPad +
      CoverImage.heightFor(width - CoverWell.inset) +
      Tokens.cardFootHeight +
      Tokens.space2 +
      CardName.heightFor(textScaler) +
      Tokens.space1 +
      MalScoreLine.heightFor(textScaler);

  @override
  Widget build(BuildContext context) {
    final loading = row.isLoadingDetails;
    final type = row.mediaType;
    final tagged =
        !loading && !row.isNotLinked && type != null && type.isNotEmpty;
    final still = MediaQuery.disableAnimationsOf(context);
    return RowTapArea(
      onOpen: onOpen,
      onContextMenu: onContextMenu,
      builder: (context, state) {
        final lit = state.hovered || state.focused;
        final malId = row.malId;
        return HoverDetails(
          focused: state.focused,
          enabled: malId != null && !TouchTarget.active,
          details: (context) => Consumer(
            builder: (context, ref, _) {
              final page = ref
                  .watch(detailPageProvider(malId!, entryId: row.entryId))
                  .value;
              return CardDetails(
                name: row.name,
                details: page?.details,
                fetch: page?.fetch ?? DetailFetch.running,
                status: row.status,
                onStatusMenu: onContextMenu,
              );
            },
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: lit && !still ? -Tokens.cardLift : 0),
            duration: chooseMotionDuration(context, Tokens.motionQuick),
            curve: Curves.easeOut,
            builder: (context, dy, child) =>
                Transform.translate(offset: Offset(0, dy), child: child),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverWell(
                    lit: lit,
                    foot: CardFoot(
                      status: row.status,
                      finished: row.allSeasonsDone,
                      count: formatLibraryCount(row),
                      showMark: showStatus,
                      showWord: lit,
                    ),
                    child: Stack(
                      children: [
                        CoverView(
                          malId: row.malId,
                          width: constraints.maxWidth - CoverWell.inset,
                          loading: loading,
                        ),
                        if (tagged)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: KeyCaps(formatType(type)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Tokens.space2),
                  CardName(row.name, loading: loading),
                  const SizedBox(height: Tokens.space1),
                  if (loading)
                    const FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Skeleton(height: Tokens.text1),
                    )
                  else if (row.isNotLinked)
                    OneLineText(
                      'Not linked',
                      style: AppText.caption(Tokens.inkMuted),
                    )
                  else
                    MalScoreLine(
                      score: row.malScore,
                      when: formatCardWhen(
                        row.startDate,
                        notAired: row.isNotAired,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
