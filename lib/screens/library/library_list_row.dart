import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/app_checkbox.dart';
import '../../components/count_display.dart';
import '../../components/faded.dart';
import '../../components/season_cap.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/row_small_line.dart';
import '../../components/skeleton_lines.dart';
import '../../components/skeleton.dart';
import '../../components/touch_target.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../icons/score_star.dart';
import '../../library/row_labels.dart';
import 'list_columns.dart';
import 'row_tap_area.dart';

/// A Library title as a row: the checkbox, the cover, the name over its type,
/// then the status word, the episode display, MAL and Your score, and the
/// three dots (shown on hover). The
/// header bar over the list names the columns (`LibraryListHeader`), so the
/// row carries no labels of its own.
class LibraryListRow extends StatefulWidget {
  const LibraryListRow({
    super.key,
    required this.row,
    required this.onOpen,
    required this.onCheck,
    required this.onContextMenu,
    required this.menu,
    this.menuShown = false,
    this.showStatus = true,
    this.faded = false,
  });

  /// The cover is grey, as while another title's quick panel is open.
  final bool faded;

  final LibraryRow row;

  final VoidCallback onOpen;

  final ValueChanged<bool> onCheck;

  final ValueChanged<Offset> onContextMenu;

  final Widget menu;

  /// Keeps the three dots showing, as while the quick panel is open.
  final bool menuShown;

  /// Off on a tab of one status, which already names it: no Status column.
  final bool showStatus;

  @override
  State<LibraryListRow> createState() => _LibraryListRowState();
}

class _LibraryListRowState extends State<LibraryListRow> {
  // the pointer is on the checkbox: it takes the hover mark, the row gives it up
  bool _overBox = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final completed = row.status == EntryStatus.completed;
    return RowTapArea(
      onOpen: widget.onOpen,
      onContextMenu: widget.onContextMenu,
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          // a narrow row also drops Your score
          final narrow = ListColumns.isNarrow(constraints.maxWidth);
          return HoverMark(
            on:
                widget.menuShown ||
                ((state.hovered || state.focused) && !_overBox),
            child: Container(
              height: Tokens.listRowHeight,
              // the checkbox's tap zone is the whole left cell, so no left padding
              padding: const EdgeInsets.only(right: Tokens.space3),
              child: Row(
                children: [
                  AppCheckbox(
                    value: completed ? CheckValue.checked : CheckValue.empty,
                    onChanged: (value) =>
                        widget.onCheck(value == CheckValue.checked),
                    onHover: (over) => setState(() => _overBox = over),
                    zone: const Size(Tokens.touchTarget, Tokens.listRowHeight),
                  ),
                  Faded(
                    on: widget.faded,
                    child: CoverView(
                      malId: row.malId,
                      width: Tokens.listCoverWidth,
                      loading: row.isLoadingDetails,
                    ),
                  ),
                  const SizedBox(width: Tokens.space3),
                  Expanded(
                    child: _Titles(
                      row,
                      narrow: narrow,
                      showStatus: widget.showStatus,
                    ),
                  ),
                  const SizedBox(width: Tokens.space3),
                  // a narrow row has no status column: the word joins the
                  // small line under the name instead
                  if (!narrow && widget.showStatus)
                    SizedBox(
                      width: ListColumns.status,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OneLineText(
                          row.status.label,
                          style: AppText.label(Tokens.inkSoft),
                        ),
                      ),
                    ),
                  _EpisodeCell(row),
                  if (!narrow) ...[
                    _MalCell(row),
                    SizedBox(
                      width: ListColumns.yourScore(context),
                      // centred under its caption
                      child: Align(
                        child: row.score == null
                            ? null
                            : CountDisplay(total: '${row.score}'),
                      ),
                    ),
                  ],
                  const SizedBox(width: Tokens.space2),
                  // the three dots show only while the row is hovered or
                  // focused (always on touch); right click does the same
                  Visibility(
                    visible:
                        widget.menuShown ||
                        state.hovered ||
                        state.focused ||
                        TouchTarget.active,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: widget.menu,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles(this.row, {required this.narrow, required this.showStatus});

  final LibraryRow row;
  final bool narrow;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    if (row.isLoadingDetails) {
      return Semantics(
        label: 'Loading details',
        child: const SkeletonLines(title: 0.6, line: 0.3),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OneLineText(row.name, style: AppText.label(Tokens.ink)),
        const SizedBox(height: Tokens.space2),
        if (row.isNotLinked)
          OneLineText('Not linked', style: AppText.caption(Tokens.inkMuted))
        else
          RowSmallLine(
            [
              if (row.mediaType case final type? when type.isNotEmpty)
                formatType(type),
              // a narrow row has no status column
              if (narrow && showStatus) row.status.label,
            ].join(' · '),
            withScore: narrow && !row.isScorePending,
            malScore: row.malScore,
          ),
      ],
    );
  }
}

/// The count with its slashes in the column's one place, and a franchise's
/// season cap hung in the slot in front of it.
class _EpisodeCell extends StatelessWidget {
  const _EpisodeCell(this.row);

  final LibraryRow row;

  @override
  Widget build(BuildContext context) {
    final season = row.seasonNumber;
    return SizedBox(
      width: ListColumns.episodes,
      child: Row(
        children: [
          SizedBox(
            width: ListColumns.seasonSlot,
            child: season == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: Tokens.space2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SeasonCap(season),
                      ),
                    ),
                  ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountDisplay.of(
                countLibraryRow(row),
                digits: ListColumns.countDigits,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// MAL's score with the gold star, "?" where MAL has none; a skeleton while
/// the details load, empty for a title with no MAL page.
class _MalCell extends StatelessWidget {
  const _MalCell(this.row);

  final LibraryRow row;

  @override
  Widget build(BuildContext context) {
    final Widget? value;
    if (row.isLoadingDetails || row.isScorePending) {
      value = const FractionallySizedBox(
        widthFactor: 0.6,
        child: Skeleton(height: Tokens.text2),
      );
    } else if (row.isNotLinked) {
      value = null;
    } else {
      value = Row(
        children: [
          const ScoreStar(size: Tokens.text1, color: Tokens.star),
          const SizedBox(width: Tokens.space1),
          Flexible(
            child: OneLineText(
              formatMalScore(row.malScore),
              style: AppText.tally(Tokens.ink, size: Tokens.text2),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: ListColumns.mal,
      child: Align(alignment: Alignment.centerLeft, child: value),
    );
  }
}
