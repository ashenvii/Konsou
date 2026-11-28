import '../../components/measure_text.dart';

import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../components/episode_column.dart';
import '../../components/one_line_text.dart';
import '../../components/pressable.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../library/library_view.dart';

/// The Library list's columns, shared by its header bar and its rows so the
/// two always line up. A row narrower than three grid cards drops the
/// status, MAL and Your score columns; the status icon leads its episode
/// cell instead.
abstract final class ListColumns {
  /// The checkbox's cell, the cover and the gap after it.
  static const lead =
      Tokens.touchTarget + Tokens.listCoverWidth + Tokens.space3;

  /// The status icon and the longest status word, "Not interested".
  static const status = Tokens.space5 * 5;

  /// The season cap's slot, then a count display of four places a side.
  static const episodes = EpisodeColumn.width;

  /// In front of the count, room for a franchise's season cap ("S2"), so the
  /// counts down the column keep one place whether a row has a cap or not.
  static const seasonSlot = Tokens.space5 + Tokens.space3;

  /// The places each number of the count takes, so the slashes line up.
  static const countDigits = 4;
  static const mal = Tokens.space5 * 2 + Tokens.space4;

  /// The menu key at the row's end and the gaps around it.
  static const trail = Tokens.space2 + Tokens.controlHeight + Tokens.space3;

  static bool isNarrow(double rowWidth) => rowWidth < EpisodeColumn.narrowBelow;

  static TextStyle captionStyle(Color color) =>
      AppText.label(color, bold: true).copyWith(
        fontSize: Tokens.text1,
        letterSpacing: Tokens.text1 * Tokens.labelTracking,
      );

  static const yourScoreLabel = 'Your score';

  /// As wide as its caption at the current text size, and never narrower
  /// than a two-digit well.
  static double yourScore(BuildContext context) {
    final width = measureText(
      yourScoreLabel,
      captionStyle(Tokens.ink),
      textScaler: MediaQuery.textScalerOf(context),
    ).width.ceilToDouble();
    return max(width + Tokens.space2, Tokens.space5 * 2);
  }
}

/// The bar over the Library list that names its columns, a hairline under
/// it and no fill of its own: the page's top gives it one once scrolled
/// (`LibraryTop`), and puts the folded title in its [lead]. Name, Episodes, MAL
/// and Your score sort the list on a click (ascending, descending, off);
/// [shown] is the sort marked on it, the bar's own or the menu's A to Z.
class LibraryListHeader extends StatelessWidget {
  const LibraryListHeader({
    super.key,
    required this.shown,
    required this.onPick,
    this.endInset = 0,
    this.lead,
    this.showStatus = true,
  });

  /// Off on a tab of one status: no Status column.
  final bool showStatus;

  /// Over the checkbox and cover: the folded title once the page scrolls.
  final Widget? lead;

  final ColumnSort? shown;
  final ValueChanged<ListColumn> onPick;

  /// Room the rows leave at their right, such as A to Z's letter strip.
  final double endInset;

  @override
  Widget build(BuildContext context) {
    Widget caption(
      ListColumn column,
      String label, {
      double? width,
      bool centred = false,
    }) {
      final cell = _Caption(
        label: label,
        centred: centred,
        sorted: shown?.column == column ? shown : null,
        onPressed: () => onPick(column),
      );
      return width == null
          ? Expanded(child: cell)
          : SizedBox(width: width, child: cell);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = ListColumns.isNarrow(constraints.maxWidth - endInset);
        return Container(
          height: Tokens.controlHeight,
          padding: EdgeInsets.only(right: endInset),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Tokens.line)),
          ),
          child: Row(
            children: [
              SizedBox(width: ListColumns.lead, child: lead),
              caption(ListColumn.name, 'Anime name'),
              const SizedBox(width: Tokens.space3),
              if (!narrow && showStatus)
                SizedBox(
                  width: ListColumns.status,
                  // drawn as a caption, but status is not a sort
                  child: const _Caption(
                    label: 'Status',
                    sorted: null,
                    onPressed: null,
                  ),
                ),
              // over the counts, past the season caps' slot
              const SizedBox(width: ListColumns.seasonSlot),
              caption(
                ListColumn.episodes,
                'Episodes',
                width: ListColumns.episodes - ListColumns.seasonSlot,
              ),
              if (!narrow) ...[
                caption(ListColumn.mal, 'MAL', width: ListColumns.mal),
                caption(
                  ListColumn.yourScore,
                  ListColumns.yourScoreLabel,
                  width: ListColumns.yourScore(context),
                  centred: true,
                ),
              ],
              const SizedBox(width: ListColumns.trail),
            ],
          ),
        );
      },
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({
    required this.label,
    required this.sorted,
    required this.onPressed,
    this.centred = false,
  });

  final String label;

  /// Over a column whose values are centred, as Your score's are.
  final bool centred;
  final ColumnSort? sorted;

  /// Null for a column that does not sort.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final sorted = this.sorted;
    final how = sorted == null
        ? 'not sorted'
        : sorted.descending
        ? 'sorted descending'
        : 'sorted ascending';
    return Pressable(
      label: onPressed == null ? label : '$label, $how',
      onPressed: onPressed,
      builder: (context, state) {
        final lit = state.hovered || state.focused;
        final color = sorted != null
            ? Tokens.ink
            : lit
            ? Tokens.inkSoft
            : Tokens.inkMuted;
        return Align(
          alignment: centred ? Alignment.center : Alignment.centerLeft,
          child: Container(
            height: Tokens.controlHeight,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: sorted != null
                      ? Tokens.pop
                      : Tokens.ground.withValues(alpha: 0),
                  width: Tokens.litEdge,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: OneLineText(
                    label,
                    style: ListColumns.captionStyle(color),
                  ),
                ),
                if (sorted != null) ...[
                  const SizedBox(width: Tokens.space1),
                  RotatedBox(
                    quarterTurns: sorted.descending ? 0 : 2,
                    child: const AppIcon(
                      AppIcons.chevronDown,
                      size: Tokens.text1,
                      color: Tokens.pop,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
