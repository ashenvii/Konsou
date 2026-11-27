import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/card_foot.dart';
import '../../components/card_name.dart';
import '../../components/cover_image.dart';
import '../../components/faded.dart';
import '../../components/motion.dart';
import '../../design/tokens.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';
import 'row_tap_area.dart';

/// A Library title as a grid card: the cover, the footer under it (status
/// icon, a franchise's season cap, the count), then the name on two lines.
/// Cover, footer and name share one left edge. The type and MAL's score are
/// in the quick panel, not on the card. Hover and keyboard focus ring the
/// cover and lift the card. Right click (a long press on touch) opens the
/// title's quick panel.
class LibraryGridCard extends StatelessWidget {
  const LibraryGridCard({
    super.key,
    required this.row,
    required this.onOpen,
    this.showStatus = true,
    required this.onContextMenu,
    this.faded = false,
    this.held = false,
  });

  /// The cover is grey, as while another card's quick panel is open.
  final bool faded;

  /// Ringed as if hovered, as the card whose quick panel is open.
  final bool held;

  final LibraryRow row;

  /// Off on a tab of one status, which already names it.
  final bool showStatus;

  final VoidCallback onOpen;

  final ValueChanged<Offset> onContextMenu;

  /// The height a card of [width] takes: the cover, the footer, the name's
  /// two lines.
  static double heightFor(double width, TextScaler textScaler) =>
      CoverImage.heightFor(width) +
      Tokens.cardFootHeight +
      Tokens.space1 +
      CardName.heightFor(textScaler);

  @override
  Widget build(BuildContext context) {
    final loading = row.isLoadingDetails;
    final still = MediaQuery.disableAnimationsOf(context);
    return RowTapArea(
      onOpen: onOpen,
      onContextMenu: onContextMenu,
      builder: (context, state) {
        final lit = held || state.hovered || state.focused;
        return TweenAnimationBuilder<double>(
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
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: Tokens.coverCorners,
                    border: Border.all(
                      color: Tokens.pop.withValues(alpha: lit ? 1 : 0),
                      width: Tokens.hoverEdge,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: Tokens.coverCorners,
                    child: Faded(
                      on: faded,
                      child: CoverView(
                        malId: row.malId,
                        width: constraints.maxWidth,
                        loading: loading,
                      ),
                    ),
                  ),
                ),
                CardFoot(
                  status: showStatus ? row.status : null,
                  count: countLibraryRow(row),
                  season: row.seasonNumber,
                ),
                const SizedBox(height: Tokens.space1),
                CardName(row.name, loading: loading),
              ],
            ),
          ),
        );
      },
    );
  }
}
