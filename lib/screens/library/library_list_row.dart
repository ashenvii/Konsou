import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/app_checkbox.dart';
import '../../components/episode_column.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/row_small_line.dart';
import '../../components/skeleton_lines.dart';
import '../../components/title_columns.dart';
import '../../components/value_column.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';
import 'row_tap_area.dart';

/// A Library title as a row: the checkbox, the cover, the name over its type
/// and year, then the episode, MAL and Your score columns and the menu.
class LibraryListRow extends StatefulWidget {
  const LibraryListRow({
    super.key,
    required this.row,
    required this.showStatus,
    required this.onOpen,
    required this.onCheck,
    required this.onContextMenu,
    required this.menu,
  });

  final LibraryRow row;

  /// A tab that mixes statuses, so the episode column names the status.
  final bool showStatus;
  final VoidCallback onOpen;

  final ValueChanged<bool> onCheck;

  final ValueChanged<Offset> onContextMenu;

  final Widget menu;

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
          final narrow = constraints.maxWidth < EpisodeColumn.narrowBelow;
          return HoverMark(
            on: (state.hovered || state.focused) && !_overBox,
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
                  CoverView(
                    malId: row.malId,
                    width: Tokens.listCoverWidth,
                    loading: row.isLoadingDetails,
                  ),
                  const SizedBox(width: Tokens.space3),
                  Expanded(child: _Titles(row, narrow: narrow)),
                  const SizedBox(width: Tokens.space3),
                  TitleColumns(
                    count: formatLibraryCount(row),
                    malScore: row.malScore,
                    narrow: narrow,
                    status: row.status,
                    finished: row.allSeasonsDone,
                    showStatus: widget.showStatus,
                    loadingDetails: row.isLoadingDetails,
                    notLinked: row.isNotLinked,
                  ),
                  if (!narrow) _YourScore(row.score),
                  const SizedBox(width: Tokens.space2),
                  widget.menu,
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
  const _Titles(this.row, {required this.narrow});

  final LibraryRow row;
  final bool narrow;

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
            formatTypeWhen(
              row.mediaType,
              row.startDate,
              notAired: row.isNotAired,
            ),
            withScore: narrow,
            malScore: row.malScore,
          ),
      ],
    );
  }
}

/// Your own score, the LED number over its label, empty when not scored. As
/// wide as its label at the current text size.
class _YourScore extends StatelessWidget {
  const _YourScore(this.score);

  final int? score;

  static const _label = 'Your score';

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppText.caption(Tokens.inkMuted);
    final painter = TextPainter(
      text: TextSpan(text: _label, style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    final score = this.score;
    return ValueColumn(
      width: width,
      value: Text(
        score == null ? '' : '$score',
        maxLines: 1,
        style: AppText.led(Tokens.pop, size: Tokens.text2),
      ),
      label: Text(_label, maxLines: 1, softWrap: false, style: labelStyle),
    );
  }
}
